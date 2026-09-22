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
    assert_equal "other", response.parsed_body.fetch("occupation_code")
    patch "/api/occupations/#{id}", params: { occupation: { name: "看護師", display_order: 20, active: false, occupation_code: "physician", id: 99 } }, headers: write_headers, as: :json
    assert_response :ok
    assert_equal id, response.parsed_body.fetch("id")
    get "/api/occupations/#{id}"
    assert_equal "看護師", response.parsed_body.fetch("name")
    assert_equal "physician", response.parsed_body.fetch("occupation_code")
  end

  test "AC-05 rejects invalid input csrf and unknown record" do
    post "/api/occupations", params: { occupation: occupation_attributes.merge(name: "", display_order: 0, occupation_code: "invalid") }, headers: write_headers, as: :json
    assert_response :unprocessable_content
    post "/api/occupations", params: { occupation: occupation_attributes }, headers: write_headers.merge("Origin" => "https://untrusted.example"), as: :json
    assert_response :forbidden
    get "/api/occupations/999999999"
    assert_response :not_found
  end

  test "AC-03 lists all records and supports partial-name and active filters" do
    active = Occupation.create!(occupation_attributes)
    inactive = Occupation.create!(occupation_attributes.merge(name: "看護師", display_order: 20, active: false))

    get "/api/occupations"
    assert_response :ok
    assert_equal [active.id, inactive.id], response.parsed_body.map { |row| row.fetch("id") }

    get "/api/occupations", params: { keyword: "看護", active: "false" }
    assert_response :ok
    assert_equal [inactive.id], response.parsed_body.map { |row| row.fetch("id") }
  end
end
