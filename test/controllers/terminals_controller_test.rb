require "test_helper"

class TerminalsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @cubao = create(:terminal, name: "Cubao", city: "Quezon City")
    @baguio = create(:terminal, name: "Baguio", city: "Baguio City")
  end

  test "returns all terminals (bounded) when no q is given" do
    get api_v1_terminals_path

    assert_response :success
    names = JSON.parse(response.body).map { |t| t["name"] }
    assert_includes names, "Cubao"
    assert_includes names, "Baguio"
  end

  test "filters by name" do
    get api_v1_terminals_path, params: { q: "Cubao" }

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body.size
    assert_equal @cubao.id, body.first["id"]
  end

  test "filters by city" do
    get api_v1_terminals_path, params: { q: "Baguio City" }

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body.size
    assert_equal @baguio.id, body.first["id"]
  end

  test "matches case-insensitively" do
    get api_v1_terminals_path, params: { q: "cubao" }

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body.size
    assert_equal @cubao.id, body.first["id"]
  end

  test "returns an empty array when nothing matches" do
    get api_v1_terminals_path, params: { q: "Nonexistent Terminal" }

    assert_response :success
    assert_equal [], JSON.parse(response.body)
  end
end
