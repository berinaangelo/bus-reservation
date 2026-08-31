require "test_helper"

class ApplicationCable::ConnectionTest < ActionCable::Connection::TestCase
  test "connects with a valid token" do
    staff = create(:operator_staff)
    _session, raw_token = OperatorSession.issue_for(staff)

    connect "/cable?token=#{raw_token}"

    assert_equal staff, connection.current_operator_staff
  end

  test "rejects connection without a token" do
    assert_reject_connection { connect "/cable" }
  end

  test "rejects connection with an invalid token" do
    assert_reject_connection { connect "/cable?token=bogus" }
  end

  test "rejects connection with an expired session's token" do
    staff = create(:operator_staff)
    session, raw_token = OperatorSession.issue_for(staff)
    session.update!(expires_at: 1.minute.ago)

    assert_reject_connection { connect "/cable?token=#{raw_token}" }
  end
end
