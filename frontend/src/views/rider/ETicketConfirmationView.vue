<script setup lang="ts">
// E-Ticket Confirmation — built from the chosen Option B ("Reference Code Hero, QR Secondary")
// full build-out in kos/decisions/ux/mockups/e-ticket-confirmation.html. Deliberate departures
// from the mockup, all backend/scope-driven, not silent omissions:
//   1. The mockup's inner "TS" branding row and its border-2 border-primary "chosen option" frame
//      are dropped — same convention every other rider screen already follows (RiderLayout
//      renders the real header; that border is the mockup gallery's own selection badge).
//   2. The "Booked Aug 26, 2026 · 3:42 PM" timestamp line is dropped — Booking has no created_at
//      (see types/booking.ts, matches app/presenters/booking_presenter.rb exactly).
//   3. The bus-class badge ("Deluxe" pill) is dropped — Booking/trip has no bus_class field.
//   4. The QR box renders the mockup's static grid-icon SVG placeholder verbatim, not a real
//      encoded QR — no QR-generation library is wired in. QR camera-scan check-in is cut from
//      MVP (staff hand-type the reference code), and the mockup itself flags this as "not a
//      decided visual treatment."
//   5. "Save Ticket" calls window.print() (see the @media print block in style.css, scoped to
//      #e-ticket-print-area below) rather than generating a downloadable image — no image-export
//      library is installed, and SMS/email notifications are cut for v1 (mvp-scope.md cut #2), so
//      this is the rider's only durable copy of the ticket.
//
// Data source: SeatSelectionView's onSubmit stashes the just-created Booking in
// checkoutStore.lastBooking before navigating here (see stores/checkout.ts's header comment) —
// GET /bookings/:reference_code requires contact_number to authorize the lookup, which reset()
// already clears by the time this view mounts, so this view can't just re-fetch by reference
// code. If lastBooking is missing or stale (page refresh, direct/bookmarked nav, browser back),
// fall back to Booking Lookup, where the rider can re-authorize a proper lookup themselves.
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { Check, ArrowRight, Download } from '@lucide/vue'
import BaseButton from '../../components/ui/BaseButton.vue'
import Empty from '../../components/ui/Empty.vue'
import { useCheckoutStore } from '../../stores/checkout'
import { formatFare, formatTime, formatDate, formatDuration } from '../../utils/format'
import type { Booking } from '../../types/booking'

const props = defineProps<{ referenceCode: string }>()

const router = useRouter()
const checkoutStore = useCheckoutStore()

const booking = ref<Booking | null>(null)
const notFoundHere = ref(false)

onMounted(() => {
  const candidate = checkoutStore.lastBooking
  if (candidate && candidate.reference_code === props.referenceCode) {
    booking.value = candidate
  } else {
    notFoundHere.value = true
  }
})

const unitFare = computed(() =>
  booking.value ? Math.round(booking.value.total_amount / booking.value.seat_count) : 0,
)

const duration = computed(() =>
  booking.value
    ? formatDuration(booking.value.trip.departure_at, booking.value.trip.arrival_at)
    : '',
)

function goToLookup() {
  router.push({ name: 'booking-lookup' })
}

function onSaveTicket() {
  window.print()
}
</script>

<template>
  <Empty
    v-if="notFoundHere"
    title="We can't show that ticket here"
    message="This confirmation is only available right after booking. Look up your booking with your reference code and contact number instead."
  >
    <template #action>
      <BaseButton variant="primary" @click="goToLookup">Look up your booking</BaseButton>
    </template>
  </Empty>

  <div v-else-if="booking" id="e-ticket-print-area" class="max-w-sm mx-auto">
    <div class="border border-border bg-background p-6">
      <!-- status -->
      <div class="flex items-center gap-2 mb-5">
        <span class="w-6 h-6 rounded-full bg-success flex items-center justify-center shrink-0">
          <Check class="w-3.5 h-3.5 text-white" stroke-width="3" />
        </span>
        <p class="text-sm font-medium">Booking Confirmed</p>
      </div>

      <!-- reference code hero + QR -->
      <div class="flex items-end justify-between gap-3 mb-1">
        <div>
          <p class="font-display uppercase tracking-wider text-[11px] text-muted mb-1">
            Reference Code
          </p>
          <p class="font-mono tabular-nums text-5xl font-semibold leading-none">
            {{ booking.reference_code }}
          </p>
        </div>
        <div class="shrink-0 text-center">
          <div class="w-20 h-20 border border-border bg-surface flex items-center justify-center">
            <svg
              class="w-11 h-11 text-muted"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="1.5"
              aria-hidden="true"
            >
              <rect x="3" y="3" width="7" height="7" />
              <rect x="14" y="3" width="7" height="7" />
              <rect x="3" y="14" width="7" height="7" />
              <rect x="14" y="14" width="3" height="3" />
              <rect x="18" y="18" width="3" height="3" />
            </svg>
          </div>
        </div>
      </div>
      <p class="text-xs text-muted mb-6">Scan not required — show this code at the counter.</p>

      <!-- dashed tear -->
      <div class="relative border-t-2 border-dashed border-border mb-6" aria-hidden="true">
        <span
          class="absolute -left-[9px] -top-[9px] w-4 h-4 rounded-full bg-background border border-border"
        />
        <span
          class="absolute -right-[9px] -top-[9px] w-4 h-4 rounded-full bg-background border border-border"
        />
      </div>

      <!-- trip detail -->
      <div class="mb-5">
        <p class="font-medium text-sm mb-2">{{ booking.trip.operator }}</p>
        <div class="flex items-center gap-2 mb-2">
          <p class="text-sm">{{ booking.trip.origin_terminal }}</p>
          <ArrowRight class="w-3.5 h-3.5 text-muted shrink-0" />
          <p class="text-sm">{{ booking.trip.destination_terminal }}</p>
        </div>
        <div class="flex items-center justify-between gap-2">
          <div>
            <p class="text-[10px] uppercase text-muted font-display tracking-wider mb-0.5">
              Departs
            </p>
            <p class="font-mono tabular-nums text-lg font-medium leading-none">
              {{ formatTime(booking.trip.departure_at) }}
            </p>
            <p class="text-[10px] text-muted mt-0.5">{{ formatDate(booking.trip.departure_at) }}</p>
          </div>
          <div class="text-right">
            <p class="text-[10px] uppercase text-muted font-display tracking-wider mb-0.5">
              Arrives
            </p>
            <p class="font-mono tabular-nums text-lg font-medium leading-none">
              {{ formatTime(booking.trip.arrival_at) }}
            </p>
            <p class="text-[10px] text-muted mt-0.5">{{ duration }}</p>
          </div>
        </div>
      </div>

      <!-- passengers -->
      <div class="mb-5 pt-4 border-t border-border">
        <p class="font-display uppercase tracking-wider text-[11px] text-muted mb-2">Passengers</p>
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

      <!-- fare -->
      <div class="mb-6 pt-4 border-t border-border">
        <div class="flex items-center justify-between text-xs text-muted mb-1">
          <span>{{ formatFare(unitFare) }} × {{ booking.seat_count }} passengers</span>
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

      <!-- CTA -->
      <BaseButton variant="primary" class="w-full" @click="onSaveTicket">
        <Download class="w-4 h-4" />
        Save Ticket
      </BaseButton>
    </div>
  </div>
</template>
