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
