# Pushes a lightweight "something changed" signal to every operator staff viewing a given trip's
# manifest -- see TripManifestView.vue. Deliberately not the source of truth for row data: the
# client reacts to a broadcast by re-calling getManifest, same as it does after its own
# check-in/payment mutations. Keeps this channel dumb and avoids two payload shapes (REST + cable)
# drifting out of sync with ManifestRowPresenter.
class ManifestChannel < ApplicationCable::Channel
  def subscribed
    trip = Trip.find_by(id: params[:trip_id])
    return reject unless trip

    # Reuses TripPolicy#manage_manifest? rather than duplicating the same_operator? check --
    # Pundit's `authorize` isn't available here (it renders/raises for a controller flow), so the
    # policy object is instantiated and called directly.
    return reject unless TripPolicy.new(current_operator_staff, trip).manage_manifest?

    stream_for trip
  end
end
