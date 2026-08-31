// Subscribes to ManifestChannel for one trip and invokes onEvent whenever the server signals a
// change (a booking landing, a check-in, a payment being marked collected) -- the caller
// (TripManifestView.vue) decides what to do (refetch + toast). Deliberately carries no state of
// its own: this is a dumb transport wrapper, not a manifest cache. Same
// subscribe-on-mount/unsubscribe-on-unmount shape as useSessionExpiryWarning.ts's interval setup.
import { onMounted, onUnmounted } from 'vue'
import type { Subscription } from '@rails/actioncable'
import { getConsumer } from '../api/cable'

export interface ManifestEvent {
  type: 'booking_created' | 'checked_in' | 'payment_collected'
}

export function useManifestChannel(tripId: () => number, onEvent: (event: ManifestEvent) => void) {
  let subscription: Subscription | null = null

  onMounted(() => {
    subscription = getConsumer().subscriptions.create(
      { channel: 'ManifestChannel', trip_id: tripId() },
      { received: (data: ManifestEvent) => onEvent(data) },
    )
  })

  onUnmounted(() => {
    subscription?.unsubscribe()
    subscription = null
  })
}
