import { ref } from 'vue'
import { defineStore } from 'pinia'
import type { Trip } from '../types/trip'

interface CheckoutPassenger {
  full_name: string
}

// In-progress checkout state, spanning Trip Search Results -> Seat Selection -> E-Ticket
// Confirmation. Not persisted (a booking either completes within one session or the rider
// restarts from search) — reset() is called after a successful POST /bookings.
export const useCheckoutStore = defineStore('checkout', () => {
  const selectedTrip = ref<Trip | null>(null)
  const tripSeatIds = ref<number[]>([])
  const passengers = ref<CheckoutPassenger[]>([])
  const contactNumber = ref('')
  const idempotencyKey = ref<string | null>(null)

  function startCheckout(trip: Trip) {
    selectedTrip.value = trip
    tripSeatIds.value = []
    passengers.value = []
    contactNumber.value = ''
    idempotencyKey.value = crypto.randomUUID()
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
    startCheckout,
    reset,
  }
})
