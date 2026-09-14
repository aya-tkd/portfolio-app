require "test_helper"

# 仮想HTTPリクエストで、ルート・CSRF・入力許可・JSON応答・DB更新をまとめて検証する。
class PatientsTest < ActionDispatch::IntegrationTest
  def write_headers
    get "/api/csrf"
    { "X-CSRF-Token" => response.parsed_body.fetch("token") }
  end

  test "AC-01 through AC-04 registration update and persistence" do
    post "/api/patients", params: { patient: patient_attributes }, headers: write_headers, as: :json
    assert_response :created
    id = response.parsed_body.fetch("id")
    assert_equal id.to_s, response.parsed_body.fetch("patient_number")
    patch "/api/patients/#{id}", params: { patient: { first_name: "次郎", birth_date: "2000-02-29", id: 999, patient_number: "999" } }, headers: write_headers, as: :json
    assert_response :ok
    assert_equal id.to_s, response.parsed_body.fetch("patient_number")
    get "/api/patients/#{id}"
    assert_equal "次郎", response.parsed_body.fetch("first_name")
    assert_equal "2000-02-29", response.parsed_body.fetch("birth_date")
    patch "/api/patients/#{id}", params: { patient: { birth_date: nil } }, headers: write_headers, as: :json
    assert_response :ok
    get "/api/patients/#{id}"
    assert_nil response.parsed_body.fetch("birth_date")
  end

  test "AC-03 invalid payload does not change database" do
    headers = write_headers
    assert_no_difference "Patient.count" do
      post "/api/patients", params: { patient: patient_attributes.merge(last_name: "", birth_date: "2025-02-29") }, headers: headers, as: :json
    end
    assert_response :unprocessable_content
    assert response.parsed_body.fetch("errors").key?("birth_date")
    patient = Patient.create!(patient_attributes)
    patch "/api/patients/#{patient.id}", params: { patient: { first_name: "", sex: "invalid" } }, headers: write_headers, as: :json
    assert_response :unprocessable_content
    assert_equal "一郎", patient.reload.first_name
  end

  test "AC-02 display number can differ from internal id" do
    patient = Patient.create!(patient_attributes)
    Patient.where(id: patient.id).update_all(patient_number: "EXT-001")
    get "/api/patients/#{patient.id}"
    assert_equal "EXT-001", response.parsed_body.fetch("patient_number")
  end

  test "AC-01 through AC-03 search matches number exactly and name or kana partially" do
    yamada = Patient.create!(patient_attributes.merge(last_name: "山田", first_name: "太郎", last_name_kana: "ヤマダ", first_name_kana: "タロウ"))
    tanaka = Patient.create!(patient_attributes.merge(last_name: "田中", first_name: "花子", last_name_kana: "タナカ", first_name_kana: "ハナコ"))
    Patient.where(id: yamada.id).update_all(patient_number: "P-100")
    Patient.where(id: tanaka.id).update_all(patient_number: "P-200")

    get "/api/patients", params: { patient_number: "P-100" }
    assert_response :ok
    assert_equal [yamada.id], response.parsed_body.pluck("id")

    get "/api/patients", params: { name: "山田 太郎" }
    assert_response :ok
    assert_equal [yamada.id], response.parsed_body.pluck("id")

    get "/api/patients", params: { name: "ヤマダ　タロウ" }
    assert_response :ok
    assert_equal [yamada.id], response.parsed_body.pluck("id")

    get "/api/patients", params: { patient_number: "P-200", name: "山田" }
    assert_response :ok
    assert_empty response.parsed_body
  end

  test "AC-01 search without conditions returns all patients in id order" do
    first = Patient.create!(patient_attributes.merge(last_name: "検索", first_name: "一郎"))
    second = Patient.create!(patient_attributes.merge(last_name: "検索", first_name: "二郎"))

    get "/api/patients"
    assert_response :ok
    ids = response.parsed_body.pluck("id")
    assert_operator ids.index(first.id), :<, ids.index(second.id)
  end

  test "AC-03 rejects CSRF and foreign origins" do
    assert_no_difference "Patient.count" do
      post "/api/patients", params: { patient: patient_attributes }, as: :json
      assert_response :forbidden
      post "/api/patients", params: { patient: patient_attributes }, headers: write_headers.merge("Origin" => "https://untrusted.example"), as: :json
      assert_response :forbidden
    end
  end

  test "AC-04 missing record returns JSON 404" do
    get "/api/patients/999999999"
    assert_response :not_found
    assert_equal "患者が見つかりません。", response.parsed_body.fetch("message")
  end
end
