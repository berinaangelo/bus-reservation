<script setup lang="ts">
// Booking Detail / Cancel — built from the chosen Option C ("Status Banner, Stacked Sections")
// full build-out in kos/decisions/ux/mockups/booking-detail-cancel.html. God moment #5
// (kos/decisions/mvp-scope.md): reference_code + contact_number is the entire v1 "account
// system" — this is the deeper "manage this booking" destination, reached from
// BookingLookupView's found panel or ETicketConfirmationView's "Manage Booking" link (both stash
// the verified pair in stores/bookingAccess.ts right before navigating here). Deliberate
// departures from the mockup:
//   1. The mockup's inner "TS" branding row and outer "chosen option" frame are dropped — same
//      convention every other rider screen already follows (RiderLayout renders the real header).
//   2. No bus-class badge ("Deluxe" pill) — Booking/trip has no such field, same departure
//      ETicketConfirmationView/BookingLookupView already document.
//   3. The mockup's static "No booking loaded" placeholder card is implemented as an actual
//      redirect (router.replace to Booking Lookup), not a rendered inert state — per the
//      mockup's own implementation notes, this screen has no lookup form of its own.
//   4. Cancelled-state copy names every released seat (not just the single-seat case) — the
//      mockup calls this out explicitly as an extension of BookingLookupView's simpler wording.
//
// Unlike ETicketConfirmationView (which trusts a cached Booking because its purpose is "what did
// I just book"), this screen always re-fetches live via GET — its purpose is *current* status,
// and a rider may return here well after the lookup that verified them.
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { Check, X, Trash2 } from '@lucide/vue'
import BaseButton from '../../components/ui/BaseButton.vue'
import BaseToast from '../../components/ui/BaseToast.vue'
import BaseDialog from '../../components/ui/BaseDialog.vue'
import { findBooking, cancelBooking } from '../../api/bookings'
import { ApiError } from '../../api/types'
import { normalizeReferenceCode } from '../../utils/referenceCode'
import { formatDate, formatTime, formatFare } from '../../utils/format'
import { useBookingAccessStore } from '../../stores/bookingAccess'
import type { Booking } from '../../types/booking'

const props = defineProps<{ referenceCode: string }>()

const router = useRouter()
const bookingAccessStore = useBookingAccessStore()

const loading = ref(false)
const errorMessage = ref<string | null>(null)
const booking = ref<Booking | null>(null)

onMounted(async () => {
  const normalizedRouteCode = normalizeReferenceCode(props.referenceCode)
  if (
    !bookingAccessStore.referenceCode ||
    bookingAccessStore.referenceCode !== normalizedRouteCode
  ) {
    // Direct/bookmarked hit, a stale store, or a different booking than was last verified — this
    // screen never re-prompts for the code itself, it hands off to Booking Lookup instead.
    router.replace({ name: 'booking-lookup' })
    return
  }

  loading.value = true
  try {
    booking.value = await findBooking(
      bookingAccessStore.referenceCode,
      bookingAccessStore.contactNumber,
    )
  } catch (e) {
    errorMessage.value = e instanceof ApiError ? e.message : 'Something went wrong. Try again.'
  } finally {
    loading.value = false
  }
})

const isCancelled = computed(() => booking.value?.status === 'cancelled')
const passengerLabel = computed(() =>
  (booking.value?.passengers.length ?? 0) > 1 ? 'Passengers' : 'Passenger',
)
const passengerCount = computed(() => booking.value?.passengers.length ?? 0)
// seat_count is null for reservable-class bookings — passenger count works for both classes
// (see types/booking.ts).
const seatCount = computed(() => booking.value?.seat_count ?? passengerCount.value)
const unitFare = computed(() =>
  booking.value && passengerCount.value > 0
    ? Math.round(booking.value.total_amount / passengerCount.value)
    : 0,
)

function joinWithAnd(items: string[]): string {
  if (items.length === 1) return items[0]!
  if (items.length === 2) return `${items[0]} and ${items[1]}`
  return `${items.slice(0, -1).join(', ')}, and ${items[items.length - 1]}`
}

// Extends BookingLookupView's cancelled copy to name every released seat, not just the
// single-seat case — see header comment #4.
const cancelledMessage = computed(() => {
  if (!booking.value) return ''
  const route = `${booking.value.trip.operator} · ${booking.value.trip.origin_terminal} → ${booking.value.trip.destination_terminal}`
  const seatNumbers = booking.value.passengers
    .map((p) => p.seat_number)
    .filter((s): s is string => s !== null)

  if (seatNumbers.length === 0) {
    return `Your booking on ${route} has been released.`
  }
  const seatLabel = seatNumbers.length === 1 ? 'Seat' : 'Seats'
  const verb = seatNumbers.length === 1 ? 'has' : 'have'
  return `${seatLabel} ${joinWithAnd(seatNumbers)} on ${route} ${verb} been released.`
})

const confirmingCancel = ref(false)
const cancelling = ref(false)

async function onConfirmCancel() {
  if (!booking.value) return

  cancelling.value = true
  try {
    booking.value = await cancelBooking(
      bookingAccessStore.referenceCode,
      bookingAccessStore.contactNumber,
    )
    confirmingCancel.value = false
  } catch (e) {
    errorMessage.value = e instanceof ApiError ? e.message : 'Something went wrong. Try again.'
    confirmingCancel.value = false
  } finally {
    cancelling.value = false
  }
}

function goToLookup() {
  router.push({ name: 'booking-lookup' })
}
</script>

<template>
  <div>
    <h1 class="font-display text-3xl font-bold mb-6">Booking Detail</h1>

    <div v-if="loading" class="flex justify-center p-8" aria-busy="true">
      <svg
        class="w-6 h-6 animate-spin text-muted"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        stroke-width="2"
        stroke-linecap="round"
        stroke-linejoin="round"
      >
        <path d="M21 12a9 9 0 1 1-6.219-8.56" />
      </svg>
    </div>

    <div v-else-if="errorMessage">
      <BaseToast variant="danger" :message="errorMessage" :dismissible="false" />
      <BaseButton variant="secondary" size="sm" class="mt-3" @click="goToLookup">
        Back to Booking Lookup
      </BaseButton>
    </div>

    <div v-else-if="booking" class="max-w-md mx-auto">
      <div class="border border-border bg-background">
        <!-- status banner -->
        <div
          class="border-y-2 px-5 py-3 flex items-center justify-between gap-2"
          :class="isCancelled ? 'bg-muted/10 border-muted' : 'bg-success/10 border-success'"
        >
          <div class="flex items-center gap-2">
            <span
              class="w-6 h-6 rounded-full flex items-center justify-center shrink-0"
              :class="isCancelled ? 'bg-muted' : 'bg-success'"
            >
              <X v-if="isCancelled" class="w-3.5 h-3.5 text-white" stroke-width="3" />
              <Check v-else class="w-3.5 h-3.5 text-white" stroke-width="3" />
            </span>
            <p class="text-sm font-medium">
              {{ isCancelled ? 'Booking Cancelled' : 'Booking Confirmed' }}
            </p>
          </div>
          <p class="font-mono tabular-nums text-base font-semibold text-text">
            {{ booking.reference_code }}
          </p>
        </div>

        <!-- cancelled body -->
        <div v-if="isCancelled" class="p-5">
          <p class="text-sm text-text leading-snug mb-2">{{ cancelledMessage }}</p>
          <p class="text-xs text-muted leading-snug">
            No refund is issued automatically for this booking — contact the operator directly if
            cash was already collected.
          </p>
        </div>

        <!-- confirmed body -->
        <template v-else>
          <div class="p-5 space-y-4">
            <div class="border border-border p-4">
              <p class="font-display uppercase tracking-wider text-[11px] text-muted mb-2">Trip</p>
              <p class="font-medium text-sm mb-1">{{ booking.trip.operator }}</p>
              <p class="text-sm mb-1">
                {{ booking.trip.origin_terminal }} → {{ booking.trip.destination_terminal }}
              </p>
              <p class="font-mono tabular-nums text-xs text-muted">
                {{ formatDate(booking.trip.departure_at) }} ·
                {{ formatTime(booking.trip.departure_at) }} →
                {{ formatTime(booking.trip.arrival_at) }}
              </p>
            </div>

            <div class="border border-border p-4">
              <p class="font-display uppercase tracking-wider text-[11px] text-muted mb-2">
                {{ passengerLabel }}
              </p>
              <div class="space-y-1.5">
                <div
                  v-for="(passenger, index) in booking.passengers"
                  :key="index"
                  class="flex items-center justify-between text-sm"
                >
                  <span>{{ passenger.full_name }}</span>
                  <span
                    v-if="passenger.seat_number !== null"
                    class="font-mono tabular-nums text-xs text-muted"
                  >
                    Seat {{ passenger.seat_number }}
                  </span>
                  <span v-else class="italic text-xs text-muted">Open seating</span>
                </div>
              </div>
              <p class="text-[11px] text-muted mt-2">Contact: {{ booking.contact_number }}</p>
            </div>

            <div class="border border-border p-4">
              <p class="font-display uppercase tracking-wider text-[11px] text-muted mb-2">Fare</p>
              <div class="flex items-center justify-between text-xs text-muted mb-1">
                <span>{{ formatFare(unitFare) }} × {{ passengerCount }} passengers</span>
                <span class="font-mono tabular-nums">{{ formatFare(booking.total_amount) }}</span>
              </div>
              <div class="flex items-center justify-between pt-2 border-t border-border">
                <p class="font-display uppercase tracking-wide text-xs font-semibold">
                  Total Due · Cash on Board
                </p>
                <p class="font-mono tabular-nums text-lg text-accent font-semibold">
                  {{ formatFare(booking.total_amount) }}
                </p>
              </div>
            </div>
          </div>

          <!-- action bar -->
          <div class="border-t border-border p-5">
            <BaseDialog
              v-if="confirmingCancel"
              message="Cancel this booking? This can't be undone."
              confirm-label="Yes, Cancel"
              cancel-label="Keep Booking"
              variant="danger"
              :loading="cancelling"
              @confirm="onConfirmCancel"
              @cancel="confirmingCancel = false"
            />
            <template v-else>
              <BaseButton variant="danger" class="w-full" @click="confirmingCancel = true">
                <Trash2 class="w-3.5 h-3.5" />
                Cancel Booking
              </BaseButton>
              <p class="text-[11px] text-muted text-center mt-2">
                Voids the booking and releases {{ seatCount }} seat{{ seatCount === 1 ? '' : 's' }}.
                No refund is issued automatically.
              </p>
            </template>
          </div>
        </template>
      </div>
    </div>
  </div>
</template>
