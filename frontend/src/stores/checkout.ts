import { ref } from 'vue'
import { defineStore } from 'pinia'
import type { Trip } from '../types/trip'
import type { Booking } from '../types/booking'

interface CheckoutPassenger {
  full_name: string
}

// In-progress checkout state, spanning Trip Search Results -> Seat Selection -> E-Ticket
// Confirmation. Not persisted (a booking either completes within one session or the rider
// restarts from search) — reset() is called after a successful POST /bookings.
//
// lastBooking is the one exception: it's deliberately kept around across reset() so E-Ticket
// Confirmation can render the just-created booking without re-fetching it — GET /bookings/:code
// requires contact_number to authorize the lookup, which reset() clears. It's a plain in-memory
// field (a page refresh loses it, by design; ETicketConfirmationView falls back to Booking
// Lookup in that case) and is cleared by startCheckout() instead, since starting a new checkout
// makes any previous confirmation stale.
export const useCheckoutStore = defineStore('checkout', () => {
  const selectedTrip = ref<Trip | null>(null)
  const tripSeatIds = ref<number[]>([])
  const passengers = ref<CheckoutPassenger[]>([])
  const contactNumber = ref('')
  const idempotencyKey = ref<string | null>(null)
  const lastBooking = ref<Booking | null>(null)

  function startCheckout(trip: Trip) {
    selectedTrip.value = trip
    tripSeatIds.value = []
    passengers.value = []
    contactNumber.value = ''
    idempotencyKey.value = crypto.randomUUID()
    lastBooking.value = null
  }

  function reset() {
    selectedTrip.value = null
    tripSeatIds.value = []
    passengers.value = []
    contactNumber.value = ''
    idempotencyKey.value = null
  }

  return {
    selectedTrip,
    tripSeatIds,
    passengers,
    contactNumber,
    idempotencyKey,
    lastBooking,
    startCheckout,
    reset,
  }
})
