require "test_helper"

class Api::V1::Operator::SessionsControllerTest < ActionDispatch::IntegrationTest
  test "valid login returns 201 with a token and creates a session" do
    staff = create(:operator_staff, email: "staff@example.com", password: "s3cret123")

    assert_difference "OperatorSession.count", 1 do
      post api_v1_operator_session_path, params: { email: "staff@example.com", password: "s3cret123" }
    end

    assert_response :created
    body = JSON.parse(response.body)
    assert body["token"].present?
    assert body["expires_at"].present?
    assert_equal staff.id, body["operator_staff"]["id"]
  end

  test "wrong password returns 401 with a generic message" do
    create(:operator_staff, email: "staff@example.com", password: "s3cret123")

    post api_v1_operator_session_path, params: { email: "staff@example.com", password: "wrong" }

    assert_response :unauthorized
    assert_equal "Incorrect email or password", JSON.parse(response.body)["error"]
  end

  test "unknown email returns the same generic message" do
    post api_v1_operator_session_path, params: { email: "nobody@example.com", password: "whatever" }

    assert_response :unauthorized
    assert_equal "Incorrect email or password", JSON.parse(response.body)["error"]
  end

  test "inactive staff cannot log in even with the correct password" do
    create(:operator_staff, email: "staff@example.com", password: "s3cret123", active: false)

    post api_v1_operator_session_path, params: { email: "staff@example.com", password: "s3cret123" }

    assert_response :unauthorized
    assert_equal "Incorrect email or password", JSON.parse(response.body)["error"]
  end

  test "missing params returns 422" do
    post api_v1_operator_session_path, params: { email: "staff@example.com" }

    assert_response :unprocessable_entity
    assert JSON.parse(response.body)["errors"]["password"].present?
  end

  test "logout revokes the session" do
    staff = create(:operator_staff)
    _session, raw_token = OperatorSession.issue_for(staff)

    delete api_v1_operator_session_path, headers: { "Authorization" => "Bearer #{raw_token}" }
    assert_response :no_content

    delete api_v1_operator_session_path, headers: { "Authorization" => "Bearer #{raw_token}" }
    assert_response :unauthorized
  end

  test "logout without a token returns 401" do
    delete api_v1_operator_session_path

    assert_response :unauthorized
  end

  test "logout with a garbage token returns 401" do
    delete api_v1_operator_session_path, headers: { "Authorization" => "Bearer not-a-real-token" }

    assert_response :unauthorized
  end
end
