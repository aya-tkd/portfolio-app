require "test_helper"

# ユーザーマスタのCRUD・関連マスタ選択・検索条件をHTTP経由で確認する。
class UsersTest < ActionDispatch::IntegrationTest
  def write_headers
    get "/api/csrf"
    { "X-CSRF-Token" => response.parsed_body.fetch("token") }
  end

  def attributes(department:, occupation:)
    { last_name: "デモ", first_name: "花子", last_name_kana: "デモ", first_name_kana: "ハナコ", department_id: department.id, occupation_id: occupation.id, active: true }
  end

  test "AC-02 through AC-05 creates searches and updates a user with master relations" do
    department = Department.create!(department_attributes)
    occupation = Occupation.create!(occupation_attributes)
    post "/api/users", params: { user: attributes(department:, occupation:) }, headers: write_headers, as: :json
    assert_response :created
    created = response.parsed_body
    assert_equal "内科", created.fetch("department_name")

    get "/api/users", params: { name: "ハナコ", department_id: department.id, occupation_id: occupation.id }
    assert_response :ok
    assert_equal [created.fetch("id")], response.parsed_body.map { |row| row.fetch("id") }

    patch "/api/users/#{created.fetch('id')}", params: { user: { first_name: "華子", active: false } }, headers: write_headers, as: :json
    assert_response :ok
    assert_equal false, response.parsed_body.fetch("active")
  end

  test "AC-05 rejects inactive related masters" do
    department = Department.create!(department_attributes.merge(active: false))
    occupation = Occupation.create!(occupation_attributes)
    post "/api/users", params: { user: attributes(department:, occupation:) }, headers: write_headers, as: :json
    assert_response :unprocessable_content
    assert response.parsed_body.fetch("errors").key?("department_id")
  end

  test "AC-02 searches by exact ID and rejects a missing related master" do
    department = Department.create!(department_attributes)
    occupation = Occupation.create!(occupation_attributes)
    post "/api/users", params: { user: attributes(department:, occupation:) }, headers: write_headers, as: :json
    created = response.parsed_body

    get "/api/users", params: { user_id: created.fetch("id") }
    assert_equal [created.fetch("id")], response.parsed_body.map { |row| row.fetch("id") }

    post "/api/users", params: { user: attributes(department:, occupation:).merge(department_id: 999_999) }, headers: write_headers, as: :json
    assert_response :unprocessable_content
    assert response.parsed_body.fetch("errors").key?("department_id")
  end
end
