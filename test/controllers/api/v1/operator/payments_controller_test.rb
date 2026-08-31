require "test_helper"

class Api::V1::Operator::PaymentsControllerTest < ActionDispatch::IntegrationTest
  include ActionCable::TestHelper

  test "toggles a payment from pending_cash to collected and back" do
    route = create(:route)
    trip = create(:trip, route: route)
    booking = create(:booking, trip: trip)
    payment = create(:payment, booking: booking, status: :pending_cash, collected_at: nil)
    staff = create(:operator_staff, operator: route.operator)
    _session, raw_token = OperatorSession.issue_for(staff)

    patch api_v1_operator_payment_path(id: payment.id), params: { collected: true }, headers: { "Authorization" => "Bearer #{raw_token}" }
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "collected", body["status"]
    assert body["collected_at"].present?

    patch api_v1_operator_payment_path(id: payment.id), params: { collected: false }, headers: { "Authorization" => "Bearer #{raw_token}" }
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "pending_cash", body["status"]
    assert_nil body["collected_at"]
  end

  test "repeating the same collected value is a no-op success" do
    route = create(:route)
    trip = create(:trip, route: route)
    booking = create(:booking, trip: trip)
    payment = create(:payment, :collected, booking: booking)
    staff = create(:operator_staff, operator: route.operator)
    _session, raw_token = OperatorSession.issue_for(staff)

    patch api_v1_operator_payment_path(id: payment.id), params: { collected: true }, headers: { "Authorization" => "Bearer #{raw_token}" }

    assert_response :success
    assert_equal "collected", JSON.parse(response.body)["status"]
  end

  test "returns 400 when collected is missing" do
    route = create(:route)
    trip = create(:trip, route: route)
    booking = create(:booking, trip: trip)
    payment = create(:payment, booking: booking)
    staff = create(:operator_staff, operator: route.operator)
    _session, raw_token = OperatorSession.issue_for(staff)

    patch api_v1_operator_payment_path(id: payment.id), headers: { "Authorization" => "Bearer #{raw_token}" }

    assert_response :bad_request
  end

  test "returns 404 for an unknown payment" do
    staff = create(:operator_staff)
    _session, raw_token = OperatorSession.issue_for(staff)

    patch api_v1_operator_payment_path(id: -1), params: { collected: true }, headers: { "Authorization" => "Bearer #{raw_token}" }

    assert_response :not_found
  end

  test "returns 403 for staff of a different operator" do
    payment = create(:payment)
    staff = create(:operator_staff)
    _session, raw_token = OperatorSession.issue_for(staff)

    patch api_v1_operator_payment_path(id: payment.id), params: { collected: true }, headers: { "Authorization" => "Bearer #{raw_token}" }

    assert_response :forbidden
  end

  test "returns 401 without a token" do
    payment = create(:payment)

    patch api_v1_operator_payment_path(id: payment.id), params: { collected: true }

    assert_response :unauthorized
  end

  test "broadcasts to the manifest channel on a real state change" do
    route = create(:route)
    trip = create(:trip, route: route)
    booking = create(:booking, trip: trip)
    payment = create(:payment, booking: booking, status: :pending_cash, collected_at: nil)
    staff = create(:operator_staff, operator: route.operator)
    _session, raw_token = OperatorSession.issue_for(staff)

    assert_broadcast_on(ManifestChannel.broadcasting_for(trip), type: "payment_collected") do
      patch api_v1_operator_payment_path(id: payment.id), params: { collected: true }, headers: { "Authorization" => "Bearer #{raw_token}" }
    end
  end

  test "does not broadcast when the collected value is unchanged" do
    route = create(:route)
    trip = create(:trip, route: route)
    booking = create(:booking, trip: trip)
    payment = create(:payment, :collected, booking: booking)
    staff = create(:operator_staff, operator: route.operator)
    _session, raw_token = OperatorSession.issue_for(staff)

    assert_no_broadcasts(ManifestChannel.broadcasting_for(trip)) do
      patch api_v1_operator_payment_path(id: payment.id), params: { collected: true }, headers: { "Authorization" => "Bearer #{raw_token}" }
    end
  end
end
