require "test_helper"

class OperatorSessionTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:operator_session).valid?
  end

  test "requires a token_digest" do
    session = build(:operator_session, token_digest: nil)
    assert_not session.valid?
    assert_includes session.errors[:token_digest], "can't be blank"
  end

  test "token_digest is unique" do
    create(:operator_session, token_digest: "dupe-digest")
    dupe = build(:operator_session, token_digest: "dupe-digest")
    assert_not dupe.valid?
    assert_includes dupe.errors[:token_digest], "has already been taken"
  end

  test "requires expires_at" do
    session = build(:operator_session, expires_at: nil)
    assert_not session.valid?
    assert_includes session.errors[:expires_at], "can't be blank"
  end

  test "issue_for persists a session whose digest matches the returned raw token" do
    staff = create(:operator_staff)
    create(:system_setting, key: "operator_session_ttl_minutes", value: "30")

    session, raw_token = OperatorSession.issue_for(staff)

    assert_equal OperatorSession.digest(raw_token), session.token_digest
    assert_in_delta 30.minutes.from_now, session.expires_at, 1.second
  end

  test "authenticate returns the session for the correct raw token" do
    staff = create(:operator_staff)
    session, raw_token = OperatorSession.issue_for(staff)

    assert_equal session, OperatorSession.authenticate(raw_token)
  end

  test "authenticate returns nil for a wrong token" do
    OperatorSession.issue_for(create(:operator_staff))

    assert_nil OperatorSession.authenticate("not-a-real-token")
  end

  test "authenticate returns nil for a blank token" do
    assert_nil OperatorSession.authenticate(nil)
    assert_nil OperatorSession.authenticate("")
  end

  test "authenticate returns nil for an expired session" do
    staff = create(:operator_staff)
    raw_token = "expired-token"
    create(:operator_session, operator_staff: staff, token_digest: OperatorSession.digest(raw_token), expires_at: 1.minute.ago)

    assert_nil OperatorSession.authenticate(raw_token)
  end

  test "expired? reflects expires_at" do
    assert build(:operator_session, expires_at: 1.minute.ago).expired?
    assert_not build(:operator_session, expires_at: 1.minute.from_now).expired?
  end

  test "renew! extends expires_at by the configured TTL from now" do
    create(:system_setting, key: "operator_session_ttl_minutes", value: "30")
    session = create(:operator_session, expires_at: 2.minutes.from_now)

    session.renew!

    assert_in_delta 30.minutes.from_now, session.expires_at, 1.second
  end
end
