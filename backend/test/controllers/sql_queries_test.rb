require "test_helper"

# SQL APIのCSRFとJSON応答を実際のルーティング経由で確認する。
class SqlQueriesTest < ActionDispatch::IntegrationTest
  test "schema API lists tables and rejects unknown names" do
    get "/api/db-schema"
    assert_response :ok
    assert_includes response.parsed_body["tables"], { "name" => "mst_patients", "category" => "master" }
    get "/api/db-schema", params: { table: "mst_patients" }
    assert_response :ok
    assert response.parsed_body["columns"].any? { |column| column["name"] == "id" }
    get "/api/db-schema", params: { table: "missing" }
    assert_response :not_found
  end

  test "CSRF is required and rows are returned" do
    post "/api/sql-query", params: { sql: "SELECT 1" }, as: :json
    assert_response :forbidden
    get "/api/csrf"
    token = response.parsed_body.fetch("token")
    post "/api/sql-query", params: { sql: "SELECT 1 AS number, NULL AS blank" }, headers: { "X-CSRF-Token" => token }, as: :json
    assert_response :ok
    assert_equal ["number", "blank"], response.parsed_body["columns"]
    assert_equal [[1, nil]], response.parsed_body["rows"]
    post "/api/sql-query", params: { sql: "DELETE FROM mst_patients" }, headers: { "X-CSRF-Token" => token }, as: :json
    assert_response :unprocessable_content
  end
end
