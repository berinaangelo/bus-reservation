<script setup lang="ts">
// Booking Lookup — built from the chosen Option C (Split Panel) full build-out in
// kos/decisions/ux/mockups/booking-lookup.html. God moment #5 (kos/decisions/mvp-scope.md):
// reference_code + contact_number is the entire v1 "account system" — no rider login, every
// lookup/cancel re-authorizes with that pair. Deliberate departures from the mockup, same
// convention every other rider screen already follows:
//   1. The mockup's inner "TS" branding row and outer border-2 border-primary "chosen option"
//      frame are dropped — RiderLayout renders the real header; that border is the mockup
//      gallery's own selection badge, not production styling.
//   2. No bus-class badge ("Deluxe" pill) — Booking/trip has no such field, same departure
//      ETicketConfirmationView already documents.
//   3. A "View full details" link was added to the found panel (not in the original mockup),
//      once BookingDetailView existed as its own destination — see that view's header comment.
//      It hands off through bookingAccess.ts; this screen's own inline find+cancel is otherwise
//      untouched, since it's a separate, already-shipped god moment, not superseded by the detail
//      page.
// The left panel (form) never resets itself based on anything that happens on the right — that
// persistence is the entire point of choosing Split Panel over Options A/B (Fitts's Law: one
// fixed target for a correction or a second lookup).
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'
import { Search, Ticket, Phone, Check, X, Trash2, ArrowRight } from '@lucide/vue'
import BaseInput from '../../components/ui/BaseInput.vue'
import BaseButton from '../../components/ui/BaseButton.vue'
import BaseToast from '../../components/ui/BaseToast.vue'
import BaseDialog from '../../components/ui/BaseDialog.vue'
import Empty from '../../components/ui/Empty.vue'
import { findBooking, cancelBooking } from '../../api/bookings'
import { ApiError } from '../../api/types'
import { normalizeReferenceCode, isValidReferenceCode } from '../../utils/referenceCode'
import { formatDate, formatTime } from '../../utils/format'
import { useBookingAccessStore } from '../../stores/bookingAccess'
import type { Booking } from '../../types/booking'

const router = useRouter()
const bookingAccessStore = useBookingAccessStore()

const referenceCode = ref('')
const contactNumber = ref('')
const referenceCodeError = ref<string | undefined>(undefined)
const contactError = ref<string | undefined>(undefined)

const normalizedCode = computed(() => normalizeReferenceCode(referenceCode.value))

// Only evaluated once a full code is typed — a half-typed code isn't "wrong" yet, just incomplete.
const codeWarning = computed(() => {
  if (normalizedCode.value.length !== 7) return undefined
  return isValidReferenceCode(normalizedCode.value)
    ? undefined
    : "Doesn't look quite right — check for a mistyped character."
})

const submitting = ref(false)
const errorMessage = ref<string | null>(null)
const booking = ref<Booking | null>(null)

const isCancelled = computed(() => booking.value?.status === 'cancelled')
const passengerLabel = computed(() =>
  (booking.value?.passengers.length ?? 0) > 1 ? 'Passengers' : 'Passenger',
)
const cancelledMessage = computed(() => {
  if (!booking.value) return ''
  const route = `${booking.value.trip.operator} · ${booking.value.trip.origin_terminal} → ${booking.value.trip.destination_terminal}`
  const [passenger] = booking.value.passengers
  if (booking.value.passengers.length === 1 && passenger?.seat_number) {
    return `Seat ${passenger.seat_number} on ${route} has been released.`
  }
  return `Your booking on ${route} has been released.`
})

function validate(): boolean {
  referenceCodeError.value = normalizedCode.value ? undefined : 'Enter your reference code.'
  contactError.value = contactNumber.value.trim() ? undefined : 'Enter your contact number.'
  return !referenceCodeError.value && !contactError.value && !codeWarning.value
}

async function onSubmit() {
  errorMessage.value = null
  if (!validate()) return

  submitting.value = true
  booking.value = null
  confirmingCancel.value = false
  try {
    booking.value = await findBooking(normalizedCode.value, contactNumber.value)
    bookingAccessStore.setVerified(normalizedCode.value, contactNumber.value)
  } catch (e) {
    errorMessage.value = e instanceof ApiError ? e.message : 'Something went wrong. Try again.'
  } finally {
    submitting.value = false
  }
}

const confirmingCancel = ref(false)
const cancelling = ref(false)

async function onConfirmCancel() {
  if (!booking.value) return

  cancelling.value = true
  try {
    booking.value = await cancelBooking(normalizedCode.value, contactNumber.value)
    confirmingCancel.value = false
  } catch (e) {
    errorMessage.value = e instanceof ApiError ? e.message : 'Something went wrong. Try again.'
    confirmingCancel.value = false
  } finally {
    cancelling.value = false
  }
}

function goToDetail() {
  if (!booking.value) return
  router.push({ name: 'booking-detail', params: { referenceCode: booking.value.reference_code } })
}
</script>

<template>
  <div>
    <h1 class="font-display text-3xl font-bold mb-6">Booking Lookup</h1>

    <div class="border border-border bg-background flex flex-col sm:flex-row">
      <!-- LEFT: lookup form -->
      <form
        class="sm:w-[42%] p-5 sm:border-r border-border transition-opacity duration-150 motion-reduce:transition-none"
        :class="{ 'opacity-60 pointer-events-none': submitting }"
        :aria-busy="submitting"
        @submit.prevent="onSubmit"
      >
        <h2 class="font-display font-bold text-base uppercase tracking-wide mb-4">
          Find your booking
        </h2>

        <BaseInput
          v-model="referenceCode"
          label="Reference code"
          placeholder="4XK-7QM-9"
          :error="referenceCodeError"
          :warning="codeWarning"
          :disabled="submitting"
          class="mb-3"
        >
          <template #leading="{ iconClass }">
            <Ticket :class="iconClass" class="w-4 h-4 shrink-0" />
          </template>
        </BaseInput>

        <BaseInput
          v-model="contactNumber"
          type="tel"
          label="Contact number"
          placeholder="09XX XXX XXXX"
          :error="contactError"
          :disabled="submitting"
          class="mb-2"
        >
          <template #leading="{ iconClass }">
            <Phone :class="iconClass" class="w-4 h-4 shrink-0" />
          </template>
        </BaseInput>
        <p class="text-[11px] text-muted mb-5">
          Same number given at checkout — used to confirm it's your booking, not just anyone with
          the code.
        </p>

        <BaseButton
          type="submit"
          variant="primary"
          class="w-full"
          :loading="submitting"
          loading-text="Searching…"
          :disabled="!!codeWarning"
        >
          <Search class="w-4 h-4" />
          Find Booking
        </BaseButton>
      </form>

      <!-- RIGHT: result panel -->
      <div class="sm:w-[58%] p-5 bg-surface">
        <BaseToast
          v-if="errorMessage"
          variant="danger"
          :message="errorMessage"
          :dismissible="false"
        />

        <div v-else-if="isCancelled">
          <div class="flex items-center gap-2 mb-2">
            <span class="w-5 h-5 rounded-full bg-muted flex items-center justify-center shrink-0">
              <X class="w-3 h-3 text-white" stroke-width="3" />
            </span>
            <p class="text-sm font-medium">Booking Cancelled</p>
          </div>
          <p class="text-sm text-text leading-snug mb-2">{{ cancelledMessage }}</p>
          <p class="text-xs text-muted leading-snug">
            No refund is issued automatically for this booking — contact the operator directly if
            cash was already collected.
          </p>
        </div>

        <div v-else-if="booking">
          <div class="flex items-center gap-2 mb-4">
            <span class="w-6 h-6 rounded-full bg-success flex items-center justify-center shrink-0">
              <Check class="w-3.5 h-3.5 text-white" stroke-width="3" />
            </span>
            <p class="text-sm font-medium">Booking Found</p>
          </div>

          <div class="border border-border bg-background p-4">
            <p class="font-medium text-sm mb-1">{{ booking.trip.operator }}</p>
            <p class="text-sm mb-1">
              {{ booking.trip.origin_terminal }} → {{ booking.trip.destination_terminal }}
            </p>
            <p class="text-xs text-muted mb-3">
              {{ formatDate(booking.trip.departure_at) }} · Departs
              {{ formatTime(booking.trip.departure_at) }}
            </p>

            <p class="font-display uppercase tracking-wider text-[11px] text-muted mb-1.5">
              {{ passengerLabel }}
            </p>
            <div class="space-y-1.5 mb-3">
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

            <div class="border-t border-border pt-3">
              <p class="font-display uppercase tracking-wider text-[10px] text-muted mb-0.5">
                Reference code
              </p>
              <p class="font-mono tabular-nums text-sm font-semibold">
                {{ booking.reference_code }}
              </p>
            </div>
          </div>

          <button
            type="button"
            class="w-full flex items-center justify-center gap-1.5 text-xs text-muted hover:text-primary mt-3 py-1 transition-colors duration-150 motion-reduce:transition-none"
            @click="goToDetail"
          >
            View full details
            <ArrowRight class="w-3.5 h-3.5" />
          </button>

          <BaseDialog
            v-if="confirmingCancel"
            class="mt-3"
            message="Cancel this booking? This can't be undone."
            confirm-label="Yes, Cancel"
            cancel-label="Keep Booking"
            variant="danger"
            :loading="cancelling"
            @confirm="onConfirmCancel"
            @cancel="confirmingCancel = false"
          />
          <BaseButton v-else variant="danger" class="w-full mt-3" @click="confirmingCancel = true">
            <Trash2 class="w-3.5 h-3.5" />
            Cancel Booking
          </BaseButton>
        </div>

        <Empty v-else title="Find a booking" message="Enter your details to find a booking">
          <template #icon="{ iconClass }">
            <Search :class="iconClass" />
          </template>
        </Empty>
      </div>
    </div>
  </div>
</template>
