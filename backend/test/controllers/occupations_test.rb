require "test_helper"

class OccupationsTest < ActionDispatch::IntegrationTest
  def write_headers
    get "/api/csrf"
    { "X-CSRF-Token" => response.parsed_body.fetch("token") }
  end

  test "AC-03 and AC-04 create update and reload" do
    post "/api/occupations", params: { occupation: occupation_attributes }, headers: write_headers, as: :json
    assert_response :created
    id = response.parsed_body.fetch("id")
    patch "/api/occupations/#{id}", params: { occupation: { name: "看護師", display_order: 20, active: false, id: 99 } }, headers: write_headers, as: :json
    assert_response :ok
    assert_equal id, response.parsed_body.fetch("id")
    get "/api/occupations/#{id}"
    assert_equal "看護師", response.parsed_body.fetch("name")
  end

  test "AC-05 rejects invalid input csrf and unknown record" do
    post "/api/occupations", params: { occupation: occupation_attributes.merge(name: "", display_order: 0) }, headers: write_headers, as: :json
    assert_response :unprocessable_content
    post "/api/occupations", params: { occupation: occupation_attributes }, headers: write_headers.merge("Origin" => "https://untrusted.example"), as: :json
    assert_response :forbidden
    get "/api/occupations/999999999"
    assert_response :not_found
  end
end
