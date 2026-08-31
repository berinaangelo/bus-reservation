require "test_helper"

class PasswordResetTokenTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:password_reset_token).valid?
  end

  test "requires a token_digest" do
    token = build(:password_reset_token, token_digest: nil)
    assert_not token.valid?
    assert_includes token.errors[:token_digest], "can't be blank"
  end

  test "token_digest is unique" do
    create(:password_reset_token, token_digest: "dupe-digest")
    dupe = build(:password_reset_token, token_digest: "dupe-digest")
    assert_not dupe.valid?
    assert_includes dupe.errors[:token_digest], "has already been taken"
  end

  test "requires expires_at" do
    token = build(:password_reset_token, expires_at: nil)
    assert_not token.valid?
    assert_includes token.errors[:expires_at], "can't be blank"
  end

  test "issue_for persists a token whose digest matches the returned raw token" do
    staff = create(:operator_staff)

    token, raw_token = PasswordResetToken.issue_for(staff)

    assert_equal PasswordResetToken.digest(raw_token), token.token_digest
    assert_in_delta PasswordResetToken::TTL.from_now, token.expires_at, 1.second
  end

  test "issue_for invalidates a prior outstanding token for the same staff" do
    staff = create(:operator_staff)
    _first_token, first_raw = PasswordResetToken.issue_for(staff)

    _second_token, second_raw = PasswordResetToken.issue_for(staff)

    assert_nil PasswordResetToken.authenticate(first_raw)
    assert_not_nil PasswordResetToken.authenticate(second_raw)
  end

  test "authenticate returns the token for the correct raw token" do
    staff = create(:operator_staff)
    token, raw_token = PasswordResetToken.issue_for(staff)

    assert_equal token, PasswordResetToken.authenticate(raw_token)
  end

  test "authenticate returns nil for a wrong token" do
    PasswordResetToken.issue_for(create(:operator_staff))

    assert_nil PasswordResetToken.authenticate("not-a-real-token")
  end

  test "authenticate returns nil for a blank token" do
    assert_nil PasswordResetToken.authenticate(nil)
    assert_nil PasswordResetToken.authenticate("")
  end

  test "authenticate returns nil for an expired token" do
    staff = create(:operator_staff)
    raw_token = "expired-token"
    create(:password_reset_token, operator_staff: staff, token_digest: PasswordResetToken.digest(raw_token), expires_at: 1.minute.ago)

    assert_nil PasswordResetToken.authenticate(raw_token)
  end
end
