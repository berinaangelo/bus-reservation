<script setup lang="ts">
// Seat Selection + Passenger Details — built from the chosen Option B (Split Panel) layout in
// kos/decisions/ux/mockups/seat-selection-passenger-details.html, plus its "same for all three
// options" Ordinary-class seat-count-stepper section. Deliberate departures from the mockup,
// resolved with the user before this was built (see the plan this was built from):
//   1. No pre-hold. Seats are only claimed/held atomically inside the final POST /bookings
//      transaction (Bookings::ClaimTripSeats) — there's no endpoint to hold a seat the moment
//      it's tapped. So the mockup's persistent "Held for 58:32" countdown is dropped; a seat tap
//      here is purely local selection until "Confirm Booking" is submitted.
//   2. Grid position is derived by parsing seat_number as "<row digits><column letter>" (e.g.
//      "1A", "10B") — see utils/seatMap.ts — since `seats` has no row/column columns of its own.
//   3. No live collision detection while browsing (also deferred). A 422 "Seat no longer
//      available" from submit triggers a silent seat-map refetch that drops just the now-stale
//      seat(s) from the current selection, keeping the rest intact for a quick resubmit.
// Also, per the same two deviations every other rider screen already makes from its own mockup:
// the mockup's inner "TS" branding row and its border-2 border-primary "chosen option" frame are
// both dropped (RiderLayout renders the real header; the border is that file's own badge, not
// production styling).
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ArrowLeft, Phone } from '@lucide/vue'
import BaseInput from '../../components/ui/BaseInput.vue'
import BaseButton from '../../components/ui/BaseButton.vue'
import BaseToast from '../../components/ui/BaseToast.vue'
import { getTripSeatMap } from '../../api/trips'
import { createBooking } from '../../api/bookings'
import { ApiError } from '../../api/types'
import { useCheckoutStore } from '../../stores/checkout'
import { groupSeatsIntoRows, hasUpperDeck } from '../../utils/seatMap'
import type { BusClass } from '../../types/trip'
import type { Deck, SeatLayout, TripSeat } from '../../types/seatMap'

const props = defineProps<{ tripId: string }>()

const MAX_SEATS = 6

const BUS_CLASS_LABELS: Record<BusClass, string> = {
  ordinary: 'Ordinary',
  aircon: 'Aircon',
  deluxe: 'Deluxe',
  double_deck: 'Double-Deck',
}
const PREMIUM_CLASSES: BusClass[] = ['deluxe', 'double_deck']

function formatFare(centavos: number | null): string {
  if (centavos === null) return '—'
  return `₱${(centavos / 100).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`
}

function formatDateTime(iso: string): string {
  return new Intl.DateTimeFormat('en-US', {
    timeZone: 'Asia/Manila',
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
    hour12: true,
  }).format(new Date(iso))
}

const router = useRouter()
const checkoutStore = useCheckoutStore()

// Checkout state is intentionally session-only (see stores/checkout.ts's own header comment) — a
// direct nav/refresh here has nothing to show, so bounce back to search rather than render a
// broken screen.
const trip = computed(() => checkoutStore.selectedTrip)
if (!trip.value) {
  router.replace({ name: 'trip-search' })
}
const isReservable = computed(() => trip.value != null && trip.value.bus_class !== 'ordinary')
const isPremium = computed(
  () => trip.value != null && PREMIUM_CLASSES.includes(trip.value.bus_class),
)

// Getting here is always a push from Trip Search Results' "Select" button (guarded above — this
// view redirects away if there's no selectedTrip), so the previous history entry is always that
// same results page with its search still in the URL. No search state needs to be threaded
// through the checkout store just for this.
function goBack() {
  router.back()
}

// --- Reservable-class seat map ---------------------------------------------------------------
const seatMap = ref<TripSeat[]>([])
const seatLayout = ref<SeatLayout | { lower: SeatLayout; upper: SeatLayout } | null>(null)
const activeDeck = ref<Deck>(null)
const loadingSeats = ref(false)
const seatMapError = ref<string | null>(null)

function columnsForActiveDeck(): number {
  const layout = seatLayout.value
  if (!layout) return 4
  if ('columns' in layout) return layout.columns
  return activeDeck.value === 'upper' ? layout.upper.columns : layout.lower.columns
}

const columns = computed(columnsForActiveDeck)
const aisleAfter = computed(() => Math.ceil(columns.value / 2))
const showDeckToggle = computed(() => hasUpperDeck(seatMap.value))
const columnLetters = computed(() =>
  Array.from({ length: columns.value }, (_, i) => String.fromCharCode(65 + i)),
)
const visibleSeats = computed(() =>
  activeDeck.value ? seatMap.value.filter((seat) => seat.deck === activeDeck.value) : seatMap.value,
)
const seatRows = computed(() => groupSeatsIntoRows(visibleSeats.value, columns.value))

async function loadSeatMap() {
  loadingSeats.value = true
  seatMapError.value = null
  try {
    const response = await getTripSeatMap(props.tripId)
    seatMap.value = response.trip_seats
    seatLayout.value = response.seat_layout
    if (!activeDeck.value) {
      activeDeck.value = hasUpperDeck(response.trip_seats) ? 'lower' : null
    }
  } catch (e) {
    seatMapError.value =
      e instanceof ApiError ? e.message : 'Could not load the seat map. Try again.'
  } finally {
    loadingSeats.value = false
  }
}

const isAtSeatCap = computed(() => checkoutStore.tripSeatIds.length >= MAX_SEATS)

function isSelected(seatId: number): boolean {
  return checkoutStore.tripSeatIds.includes(seatId)
}

function seatStateLabel(seat: TripSeat): string {
  if (isSelected(seat.id)) return 'selected'
  if (seat.status === 'booked') return 'taken'
  if (seat.status === 'held') return 'held by another rider'
  if (isAtSeatCap.value) return 'available, but the 6-seat limit is reached'
  return 'available'
}

function seatTileClass(seat: TripSeat): string {
  if (isSelected(seat.id)) {
    return 'bg-primary border border-primary text-white font-semibold'
  }
  if (seat.status === 'booked') {
    return 'bg-danger border border-danger text-white/90 cursor-not-allowed'
  }
  if (seat.status === 'held') {
    return 'border border-warning bg-warning/10 text-warning cursor-not-allowed'
  }
  if (isAtSeatCap.value) {
    return 'border border-border bg-surface text-muted cursor-not-allowed opacity-60'
  }
  return 'border border-success bg-success/10 text-success hover:bg-success/20 transition-colors duration-150 motion-reduce:transition-none'
}

function toggleSeat(seat: TripSeat) {
  const idx = checkoutStore.tripSeatIds.indexOf(seat.id)
  if (idx !== -1) {
    checkoutStore.tripSeatIds.splice(idx, 1)
    checkoutStore.passengers.splice(idx, 1)
    return
  }
  if (seat.status !== 'available' || isAtSeatCap.value) return
  checkoutStore.tripSeatIds.push(seat.id)
  checkoutStore.passengers.push({ full_name: '' })
}

// --- Ordinary-class seat-count stepper --------------------------------------------------------
const ordinaryCap = computed(() => Math.min(MAX_SEATS, trip.value?.seats_available ?? MAX_SEATS))

function incrementOrdinarySeats() {
  if (checkoutStore.passengers.length >= ordinaryCap.value) return
  checkoutStore.passengers.push({ full_name: '' })
}

function decrementOrdinarySeats() {
  if (checkoutStore.passengers.length <= 1) return
  checkoutStore.passengers.pop()
}

// --- Shared: passengers, contact number, fare, submit ------------------------------------------
const seatCount = computed(() => checkoutStore.passengers.length)
const fareTotal = computed(() => seatCount.value * (trip.value?.fare ?? 0))

const contactError = ref<string | undefined>(undefined)
const passengerErrors = ref<Record<number, string | undefined>>({})
const submitError = ref<string | null>(null)
const submitting = ref(false)

function passengerLabel(index: number, seat: TripSeat | undefined): string {
  return seat ? seat.seat_number : `Passenger ${index + 1}`
}

function seatForPassengerIndex(index: number): TripSeat | undefined {
  const seatId = checkoutStore.tripSeatIds[index]
  return seatMap.value.find((seat) => seat.id === seatId)
}

function validate(): boolean {
  contactError.value = checkoutStore.contactNumber.trim() ? undefined : 'Enter a contact number.'
  passengerErrors.value = {}
  let hasPassengerError = false
  checkoutStore.passengers.forEach((passenger, index) => {
    if (!passenger.full_name.trim()) {
      passengerErrors.value[index] = 'Enter a full name.'
      hasPassengerError = true
    }
  })

  if (checkoutStore.passengers.length === 0) {
    submitError.value = 'Select at least one seat.'
    return false
  }

  return !contactError.value && !hasPassengerError
}

// Drops any currently-selected seat that a refetched seat map no longer reports as available —
// we never held it server-side, so "available" is the only status that still means "still
// selectable" for a seat that was previously picked here.
async function recoverFromSeatConflict() {
  try {
    const response = await getTripSeatMap(props.tripId)
    seatMap.value = response.trip_seats
    const stillAvailable = new Set(
      response.trip_seats.filter((seat) => seat.status === 'available').map((seat) => seat.id),
    )
    for (let i = checkoutStore.tripSeatIds.length - 1; i >= 0; i--) {
      if (!stillAvailable.has(checkoutStore.tripSeatIds[i]!)) {
        checkoutStore.tripSeatIds.splice(i, 1)
        checkoutStore.passengers.splice(i, 1)
      }
    }
  } catch {
    // Best-effort refresh — the stale selection just stays until the next submit attempt.
  }
}

async function onSubmit() {
  submitError.value = null
  if (!validate() || !trip.value || !checkoutStore.idempotencyKey) return

  submitting.value = true
  try {
    const booking = await createBooking({
      trip_id: trip.value.id,
      contact_number: checkoutStore.contactNumber,
      idempotency_key: checkoutStore.idempotencyKey,
      trip_seat_ids: isReservable.value ? checkoutStore.tripSeatIds : [],
      passengers: checkoutStore.passengers,
    })
    checkoutStore.reset()
    router.push({ name: 'e-ticket', params: { referenceCode: booking.reference_code } })
  } catch (e) {
    if (e instanceof ApiError && isReservable.value && e.message === 'Seat no longer available') {
      submitError.value =
        'One of your selected seats was just taken. Pick a replacement to continue.'
      await recoverFromSeatConflict()
    } else {
      submitError.value = e instanceof ApiError ? e.message : 'Something went wrong. Try again.'
    }
  } finally {
    submitting.value = false
  }
}

onMounted(() => {
  if (!trip.value) return
  if (isReservable.value) {
    loadSeatMap()
  } else if (checkoutStore.passengers.length === 0) {
    checkoutStore.passengers.push({ full_name: '' })
  }
})
</script>

<template>
  <div v-if="trip">
    <BaseButton variant="secondary" size="sm" class="mb-4" @click="goBack">
      <ArrowLeft class="w-4 h-4" />
      Back to results
    </BaseButton>

    <BaseToast
      v-if="submitError"
      variant="danger"
      :message="submitError"
      dismissible
      class="mb-4"
      @dismiss="submitError = null"
    />
    <BaseToast
      v-if="seatMapError"
      variant="danger"
      :message="seatMapError"
      :dismissible="false"
      class="mb-4"
    />

    <div class="border border-border bg-background p-4 sm:p-8">
      <!-- trip summary strip -->
      <div
        class="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-6 pb-6 border-b border-border"
      >
        <div>
          <p class="font-medium text-base">
            {{ trip.operator }} · {{ trip.origin_terminal }} → {{ trip.destination_terminal }}
          </p>
          <div class="flex items-center gap-2 mt-1.5">
            <span
              class="inline-flex items-center gap-1 px-2 py-0.5 font-display uppercase tracking-wide text-[11px] font-semibold"
              :class="
                isPremium
                  ? 'border border-secondary bg-secondary/10 text-secondary'
                  : 'border border-border text-muted'
              "
            >
              {{ BUS_CLASS_LABELS[trip.bus_class] }}
            </span>
            <span class="text-xs text-muted font-mono tabular-nums">{{
              formatDateTime(trip.departure_at)
            }}</span>
          </div>
        </div>
        <div class="text-left sm:text-right">
          <p class="font-display uppercase tracking-wider text-[11px] text-muted mb-0.5">
            Fare per seat
          </p>
          <p class="font-mono tabular-nums text-xl text-accent font-semibold">
            {{ formatFare(trip.fare) }}
          </p>
        </div>
      </div>

      <div v-if="loadingSeats" class="flex justify-center p-8" aria-busy="true">
        <svg
          class="w-6 h-6 animate-spin text-muted"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
        >
          <path d="M21 12a9 9 0 1 1-6.219-8.56" />
        </svg>
      </div>

      <!-- ============== RESERVABLE CLASSES: split panel ============== -->
      <div v-else-if="isReservable" class="flex flex-col lg:flex-row gap-6 lg:gap-8">
        <div class="lg:flex-1 min-w-0">
          <!-- seat legend -->
          <div class="flex flex-wrap items-center gap-4 sm:gap-6 mb-6 pb-5 border-b border-border">
            <div class="flex items-center gap-2">
              <span class="w-6 h-6 border border-success bg-success/10" aria-hidden="true" />
              <span class="text-xs text-muted">Available</span>
            </div>
            <div class="flex items-center gap-2">
              <span class="w-6 h-6 bg-primary" aria-hidden="true" />
              <span class="text-xs text-muted">Selected</span>
            </div>
            <div class="flex items-center gap-2">
              <span class="w-6 h-6 border border-warning bg-warning/10" aria-hidden="true" />
              <span class="text-xs text-muted">Held</span>
            </div>
            <div class="flex items-center gap-2">
              <span class="w-6 h-6 bg-danger" aria-hidden="true" />
              <span class="text-xs text-muted">Taken</span>
            </div>
          </div>

          <!-- deck toggle -->
          <template v-if="showDeckToggle">
            <div class="inline-flex border border-border mb-1.5" role="tablist" aria-label="Deck">
              <button
                type="button"
                role="tab"
                :aria-selected="activeDeck === 'lower'"
                class="px-4 py-2.5 font-display uppercase tracking-wide text-xs font-semibold transition-colors duration-150 motion-reduce:transition-none focus:outline-none focus:ring-2 focus:ring-primary"
                :class="
                  activeDeck === 'lower' ? 'bg-primary text-white' : 'text-muted hover:text-primary'
                "
                @click="activeDeck = 'lower'"
              >
                Lower Deck
              </button>
              <button
                type="button"
                role="tab"
                :aria-selected="activeDeck === 'upper'"
                class="px-4 py-2.5 font-display uppercase tracking-wide text-xs font-semibold border-l border-border transition-colors duration-150 motion-reduce:transition-none focus:outline-none focus:ring-2 focus:ring-primary"
                :class="
                  activeDeck === 'upper' ? 'bg-primary text-white' : 'text-muted hover:text-primary'
                "
                @click="activeDeck = 'upper'"
              >
                Upper Deck
              </button>
            </div>
            <p class="text-[11px] text-muted mb-5">
              Double-deck only — aircon/deluxe skip straight to the grid.
            </p>
          </template>

          <!-- seat grid -->
          <p class="text-center text-[11px] uppercase tracking-wider text-muted mb-3">
            — Front of bus —
          </p>
          <div class="flex justify-center mb-2">
            <div class="flex items-center gap-1.5 sm:gap-2 pl-6">
              <template v-for="(letter, i) in columnLetters" :key="letter">
                <span class="w-9 sm:w-10 text-center text-[10px] text-muted font-mono">{{
                  letter
                }}</span>
                <span
                  v-if="i + 1 === aisleAfter && i + 1 < columnLetters.length"
                  class="w-3 sm:w-5"
                />
              </template>
            </div>
          </div>

          <div class="flex justify-center">
            <div class="flex flex-col gap-1.5 sm:gap-2">
              <div
                v-for="seatRow in seatRows"
                :key="seatRow.row"
                class="flex items-center gap-1.5 sm:gap-2"
              >
                <span class="w-5 shrink-0 text-[11px] font-mono text-muted text-right">{{
                  seatRow.row
                }}</span>
                <template v-for="(seat, i) in seatRow.seats" :key="i">
                  <button
                    v-if="seat && (seat.status === 'available' || isSelected(seat.id))"
                    type="button"
                    :aria-label="`Seat ${seat.seat_number}, ${seatStateLabel(seat)}`"
                    :aria-pressed="isSelected(seat.id)"
                    class="w-9 h-9 sm:w-10 sm:h-10 flex items-center justify-center font-mono text-[11px] font-medium focus:outline-none focus:ring-2 focus:ring-primary"
                    :class="seatTileClass(seat)"
                    @click="toggleSeat(seat)"
                  >
                    {{ seat.seat_number }}
                  </button>
                  <span
                    v-else-if="seat"
                    :aria-label="`Seat ${seat.seat_number}, ${seatStateLabel(seat)}`"
                    :title="seat.status === 'booked' ? 'Already booked' : 'Held by another rider'"
                    class="w-9 h-9 sm:w-10 sm:h-10 flex items-center justify-center font-mono text-[11px] font-medium"
                    :class="seatTileClass(seat)"
                  >
                    {{ seat.seat_number }}
                  </span>
                  <span v-else class="w-9 h-9 sm:w-10 sm:h-10" aria-hidden="true" />
                  <span
                    v-if="i + 1 === aisleAfter && i + 1 < seatRow.seats.length"
                    class="w-3 sm:w-5"
                  />
                </template>
              </div>
            </div>
          </div>
        </div>

        <!-- RIGHT: booking summary panel -->
        <div class="lg:w-80 shrink-0">
          <div class="lg:sticky lg:top-6 border border-border bg-surface p-4 sm:p-5">
            <p class="text-[11px] text-muted mb-4">
              Seats aren't reserved until you confirm your booking.
            </p>

            <h4 class="font-display font-bold text-sm uppercase tracking-wide mb-3">
              Your Booking
            </h4>
            <div v-if="checkoutStore.passengers.length === 0" class="text-xs text-muted mb-4">
              Tap a seat to add a passenger.
            </div>
            <div v-else class="flex flex-col gap-2.5 mb-4">
              <div
                v-for="(passenger, index) in checkoutStore.passengers"
                :key="checkoutStore.tripSeatIds[index]"
              >
                <div class="flex items-center gap-2.5">
                  <span
                    class="shrink-0 w-11 text-center font-mono text-[11px] font-semibold bg-primary text-white py-1"
                  >
                    {{ passengerLabel(index, seatForPassengerIndex(index)) }}
                  </span>
                  <BaseInput
                    v-model="passenger.full_name"
                    placeholder="Full name"
                    :error="passengerErrors[index]"
                    class="flex-1"
                  />
                </div>
              </div>
            </div>

            <BaseInput
              v-model="checkoutStore.contactNumber"
              type="tel"
              label="Contact number"
              placeholder="09XX XXX XXXX"
              :error="contactError"
              class="mb-1.5"
            >
              <template #leading="{ iconClass }">
                <Phone :class="iconClass" class="w-4 h-4 shrink-0" />
              </template>
            </BaseInput>
            <p class="text-[10px] text-muted mb-4">
              One number for this booking — not per passenger.
            </p>

            <div class="flex items-center justify-between pt-3 mb-4 border-t border-border">
              <span class="text-xs text-muted font-mono tabular-nums"
                >{{ seatCount }} × {{ formatFare(trip.fare) }}</span
              >
              <span class="font-mono tabular-nums text-lg text-accent font-semibold">{{
                formatFare(fareTotal)
              }}</span>
            </div>

            <BaseButton
              type="submit"
              variant="primary"
              class="w-full"
              :loading="submitting"
              loading-text="Confirming…"
              @click="onSubmit"
            >
              Confirm Booking
            </BaseButton>
            <p class="text-[10px] text-muted text-center mt-2">Up to 6 seats per booking.</p>
          </div>
        </div>
      </div>

      <!-- ============== ORDINARY CLASS: seat-count stepper ============== -->
      <div v-else>
        <div class="mb-6">
          <label class="block font-display uppercase tracking-wider text-[11px] text-muted mb-2">
            Number of seats
          </label>
          <div class="flex items-center gap-4">
            <div class="inline-flex items-stretch border border-border">
              <BaseButton
                type="button"
                icon-only
                aria-label="Decrease seat count"
                :disabled="seatCount <= 1"
                @click="decrementOrdinarySeats"
              >
                −
              </BaseButton>
              <span
                class="w-14 h-11 flex items-center justify-center font-mono tabular-nums text-lg font-medium"
              >
                {{ seatCount }}
              </span>
              <BaseButton
                type="button"
                icon-only
                aria-label="Increase seat count"
                :disabled="seatCount >= ordinaryCap"
                @click="incrementOrdinarySeats"
              >
                +
              </BaseButton>
            </div>
            <span class="text-xs text-muted font-mono tabular-nums">
              {{ trip.seats_available }} seats left · up to 6 per booking
            </span>
          </div>
        </div>

        <p class="text-[11px] text-muted mb-6">
          Seats aren't reserved until you confirm your booking.
        </p>

        <h4 class="font-display font-bold text-sm uppercase tracking-wide mb-3">Passengers</h4>
        <div class="flex flex-col gap-3 mb-4">
          <div
            v-for="(passenger, index) in checkoutStore.passengers"
            :key="index"
            class="flex items-center gap-3"
          >
            <span class="shrink-0 w-24 font-display uppercase tracking-wide text-[11px] text-muted">
              Passenger {{ index + 1 }}
            </span>
            <BaseInput
              v-model="passenger.full_name"
              placeholder="Full name"
              :error="passengerErrors[index]"
              class="flex-1"
            />
          </div>
        </div>

        <BaseInput
          v-model="checkoutStore.contactNumber"
          type="tel"
          label="Contact number"
          placeholder="09XX XXX XXXX"
          :error="contactError"
          class="mb-2"
        >
          <template #leading="{ iconClass }">
            <Phone :class="iconClass" class="w-4 h-4 shrink-0" />
          </template>
        </BaseInput>
        <p class="text-[11px] text-muted mb-6">
          One number for this whole booking — not per passenger.
        </p>

        <div
          class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pt-5 border-t border-border"
        >
          <div>
            <p class="font-mono tabular-nums text-lg">
              <span class="text-muted">{{ seatCount }} × {{ formatFare(trip.fare) }} =</span>
              <span class="text-accent font-semibold">{{ formatFare(fareTotal) }}</span>
            </p>
            <p class="text-[11px] text-muted mt-0.5">Up to 6 seats per booking.</p>
          </div>
          <BaseButton
            type="submit"
            variant="primary"
            class="sm:w-64"
            :loading="submitting"
            loading-text="Confirming…"
            @click="onSubmit"
          >
            Confirm Booking
          </BaseButton>
        </div>
      </div>
    </div>
  </div>
</template>
