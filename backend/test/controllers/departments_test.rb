require "test_helper"

# 仮想HTTPリクエストで、診療科のルート・CSRF・入力許可・JSON応答・DB更新をまとめて確認する。
class DepartmentsTest < ActionDispatch::IntegrationTest
  def write_headers
    get "/api/csrf"
    { "X-CSRF-Token" => response.parsed_body.fetch("token") }
  end

  test "AC-03 and AC-04 create update reload and retain database id" do
    post "/api/departments", params: { department: department_attributes }, headers: write_headers, as: :json
    assert_response :created
    created = response.parsed_body
    id = created.fetch("id")
    assert_equal "内科", created.fetch("name")
    assert_equal true, created.fetch("active")

    patch "/api/departments/#{id}", params: { department: { name: "総合内科", display_order: 20, active: false, id: 999 } }, headers: write_headers, as: :json
    assert_response :ok
    assert_equal id, response.parsed_body.fetch("id")
    assert_equal false, response.parsed_body.fetch("active")

    get "/api/departments/#{id}"
    assert_response :ok
    assert_equal "総合内科", response.parsed_body.fetch("name")
    assert_equal 20, response.parsed_body.fetch("display_order")
    assert_equal "ナイカ", response.parsed_body.fetch("kana_name")
  end

  test "AC-05 invalid payload returns fields and keeps database unchanged" do
    headers = write_headers
    assert_no_difference "Department.count" do
      post "/api/departments", params: { department: department_attributes.merge(name: "", display_order: 0) }, headers: headers, as: :json
    end
    assert_response :unprocessable_content
    assert response.parsed_body.fetch("errors").key?("name")
    assert response.parsed_body.fetch("errors").key?("display_order")
  end

  test "AC-05 rejects CSRF and unknown id as JSON" do
    post "/api/departments", params: { department: department_attributes }, as: :json
    assert_response :forbidden
    get "/api/departments/999999999"
    assert_response :not_found
    assert_equal "診療科が見つかりません。", response.parsed_body.fetch("message")
  end
end
