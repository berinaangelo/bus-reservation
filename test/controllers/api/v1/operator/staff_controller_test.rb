require "test_helper"

class Api::V1::Operator::StaffControllerTest < ActionDispatch::IntegrationTest
  def auth_headers_for(staff)
    _session, raw_token = OperatorSession.issue_for(staff)
    { "Authorization" => "Bearer #{raw_token}" }
  end

  test "index lists only the current staff member's own operator's staff" do
    operator = create(:operator)
    staff = create(:operator_staff, operator: operator)
    coworker = create(:operator_staff, operator: operator)
    create(:operator_staff) # different operator

    get api_v1_operator_staff_index_path, headers: auth_headers_for(staff)

    assert_response :ok
    ids = JSON.parse(response.body)["staff"].map { |s| s["id"] }
    assert_equal [ staff.id, coworker.id ].sort, ids.sort
  end

  test "index requires authentication" do
    get api_v1_operator_staff_index_path

    assert_response :unauthorized
  end

  test "inviting a staff member creates an unusable-password record, sends the invite email, and issues a reset token" do
    staff = create(:operator_staff)

    assert_emails 1 do
      assert_difference [ "OperatorStaff.count", "PasswordResetToken.count" ], 1 do
        post api_v1_operator_staff_index_path,
          params: { name: "New Hire", email: "newhire@example.com" },
          headers: auth_headers_for(staff)
      end
    end

    assert_response :created
    body = JSON.parse(response.body)
    invited = OperatorStaff.find(body["id"])
    assert_equal "New Hire", invited.name
    assert_equal "newhire@example.com", invited.email
    assert_equal staff.operator_id, invited.operator_id
    assert_not invited.authenticate("") # unusable password: never left blank/guessable
  end

  test "inviting with a duplicate email returns 422" do
    staff = create(:operator_staff)
    create(:operator_staff, email: "taken@example.com")

    assert_no_emails do
      post api_v1_operator_staff_index_path,
        params: { name: "New Hire", email: "taken@example.com" },
        headers: auth_headers_for(staff)
    end

    assert_response :unprocessable_entity
    assert JSON.parse(response.body)["errors"]["email"].present?
  end

  test "inviting with a blank name returns 422" do
    staff = create(:operator_staff)

    post api_v1_operator_staff_index_path,
      params: { name: "", email: "newhire@example.com" },
      headers: auth_headers_for(staff)

    assert_response :unprocessable_entity
    assert JSON.parse(response.body)["errors"]["name"].present?
  end

  test "deactivating a coworker revokes their existing sessions" do
    operator = create(:operator)
    staff = create(:operator_staff, operator: operator)
    coworker = create(:operator_staff, operator: operator)
    OperatorSession.issue_for(coworker)

    patch api_v1_operator_staff_path(coworker), params: { active: false }, headers: auth_headers_for(staff)

    assert_response :ok
    coworker.reload
    assert_not coworker.active?
    assert_equal 0, coworker.operator_sessions.count
  end

  test "reactivating a coworker does not touch other sessions" do
    operator = create(:operator)
    staff = create(:operator_staff, operator: operator)
    coworker = create(:operator_staff, operator: operator, active: false)

    patch api_v1_operator_staff_path(coworker), params: { active: true }, headers: auth_headers_for(staff)

    assert_response :ok
    assert coworker.reload.active?
  end

  test "cannot manage staff from a different operator" do
    staff = create(:operator_staff)
    other_operator_staff = create(:operator_staff)

    patch api_v1_operator_staff_path(other_operator_staff), params: { active: false }, headers: auth_headers_for(staff)

    assert_response :forbidden
  end
end
