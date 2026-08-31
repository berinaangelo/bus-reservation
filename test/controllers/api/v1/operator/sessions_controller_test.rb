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

  test "renewing extends the session's expiry without changing the token" do
    staff = create(:operator_staff)
    session, raw_token = OperatorSession.issue_for(staff)
    original_expiry = session.expires_at

    travel 1.minute do
      patch api_v1_operator_session_path, headers: { "Authorization" => "Bearer #{raw_token}" }
    end

    assert_response :ok
    session.reload
    assert_operator session.expires_at, :>, original_expiry
    assert_equal session.expires_at.iso8601, JSON.parse(response.body)["expires_at"]
    assert_equal session, OperatorSession.authenticate(raw_token)
  end

  test "renewing without a token returns 401" do
    patch api_v1_operator_session_path

    assert_response :unauthorized
  end

  test "renewing with a garbage token returns 401" do
    patch api_v1_operator_session_path, headers: { "Authorization" => "Bearer not-a-real-token" }

    assert_response :unauthorized
  end

  test "renewing an already-expired session returns 401" do
    staff = create(:operator_staff)
    _session, raw_token = OperatorSession.issue_for(staff)

    travel (SystemSetting.operator_session_ttl_minutes + 1).minutes do
      patch api_v1_operator_session_path, headers: { "Authorization" => "Bearer #{raw_token}" }
    end

    assert_response :unauthorized
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

  test "locks the account after the threshold of failed attempts" do
    staff = create(:operator_staff, email: "staff@example.com", password: "s3cret123")

    OperatorStaff::LOCKOUT_THRESHOLD.times do
      post api_v1_operator_session_path, params: { email: "staff@example.com", password: "wrong" }
      assert_response :unauthorized
    end

    assert staff.reload.locked?
  end

  test "the correct password on a locked account returns the lockout message" do
    staff = create(:operator_staff, email: "staff@example.com", password: "s3cret123")
    OperatorStaff::LOCKOUT_THRESHOLD.times { staff.register_failed_attempt! }

    post api_v1_operator_session_path, params: { email: "staff@example.com", password: "s3cret123" }

    assert_response :unauthorized
    assert_equal OperatorStaff::LOCKOUT_MESSAGE, JSON.parse(response.body)["error"]
  end

  test "a wrong password on a locked account still returns the generic message" do
    staff = create(:operator_staff, email: "staff@example.com", password: "s3cret123")
    OperatorStaff::LOCKOUT_THRESHOLD.times { staff.register_failed_attempt! }

    post api_v1_operator_session_path, params: { email: "staff@example.com", password: "wrong" }

    assert_response :unauthorized
    assert_equal "Incorrect email or password", JSON.parse(response.body)["error"]
  end

  test "login succeeds again once the lockout duration has elapsed" do
    staff = create(:operator_staff, email: "staff@example.com", password: "s3cret123")
    OperatorStaff::LOCKOUT_THRESHOLD.times { staff.register_failed_attempt! }

    travel (OperatorStaff::LOCKOUT_DURATION + 1.minute) do
      post api_v1_operator_session_path, params: { email: "staff@example.com", password: "s3cret123" }
    end

    assert_response :created
    assert_equal 0, staff.reload.failed_attempts
    assert_nil staff.locked_at
  end

  test "a successful login resets a nonzero but under-threshold failed_attempts count" do
    staff = create(:operator_staff, email: "staff@example.com", password: "s3cret123")
    2.times { staff.register_failed_attempt! }

    post api_v1_operator_session_path, params: { email: "staff@example.com", password: "s3cret123" }

    assert_response :created
    assert_equal 0, staff.reload.failed_attempts
  end
end
