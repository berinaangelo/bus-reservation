<script setup lang="ts">
// Trip Manifest — Roster Table + Quick Check-in Bar (chosen option), see
// kos/decisions/ux/mockups/trip-manifest.html. Same local-refs-no-store shape as
// OperatorTripsView.vue, but read+mutate instead of full CRUD: the roster/summary come from
// getManifest, check-in and paid-toggle are two small dedicated mutation endpoints
// (checkIns.ts / payments.ts) rather than a drawer form. Live updates (a booking/check-in/payment
// landing while this screen is open) push over ManifestChannel via useManifestChannel — see that
// composable for the transport, this view just reacts to the signal by refetching.
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ArrowLeft, Check, Lock, Search, Users } from '@lucide/vue'
import { getManifest } from '../../api/operator/manifest'
import { checkIn } from '../../api/operator/checkIns'
import { updatePayment } from '../../api/operator/payments'
import { getTrip } from '../../api/operator/trips'
import type { ManifestRow, ManifestSummary } from '../../types/operator'
import type { PaginationMeta } from '../../api/types'
import type { OperatorTrip, BusClass, TripStatus } from '../../types/trip'
import { ApiError } from '../../api/types'
import { formatDateTime } from '../../utils/format'
import { useManifestChannel } from '../../composables/useManifestChannel'
import BaseButton from '../../components/ui/BaseButton.vue'
import BaseInput from '../../components/ui/BaseInput.vue'
import BaseToast from '../../components/ui/BaseToast.vue'
import Empty from '../../components/ui/Empty.vue'

const props = defineProps<{ tripId: string }>()
const router = useRouter()
const tripIdNum = computed(() => Number(props.tripId))

const BUS_CLASS_LABELS: Record<BusClass, string> = {
  ordinary: 'Ordinary',
  aircon: 'Aircon',
  deluxe: 'Deluxe',
  double_deck: 'Double-Deck',
}

// Same set the manifest's trip_status can be. "Boarding closed" locks check-in/payment actions —
// scheduled/boarding trips stay open.
const CLOSED_STATUSES: TripStatus[] = ['departed', 'completed', 'cancelled']

const trip = ref<OperatorTrip | null>(null)
const summary = ref<ManifestSummary | null>(null)
const rows = ref<ManifestRow[]>([])
const meta = ref<PaginationMeta | null>(null)

const loading = ref(true) // first paint only — trip header + page 1
const manifestLoading = ref(false) // page-change reloads, header/summary stay put
const loadError = ref<string | null>(null)
const noopNotice = ref<string | null>(null)
const liveUpdateNotice = ref<string | null>(null)

const LIVE_UPDATE_MESSAGES = {
  booking_created: 'A new booking just came in.',
  checked_in: 'A passenger just checked in.',
  payment_collected: 'A payment was just marked collected.',
} as const

const boardingClosed = computed(
  () => !!summary.value && CLOSED_STATUSES.includes(summary.value.trip_status),
)
const allCheckedIn = computed(
  () =>
    !!summary.value &&
    summary.value.total_passengers > 0 &&
    summary.value.checked_in === summary.value.total_passengers,
)

async function loadManifest(page = meta.value?.page ?? 1) {
  const res = await getManifest(tripIdNum.value, page)
  summary.value = res.summary
  rows.value = res.rows
  meta.value = res.meta
}

async function load() {
  loading.value = true
  loadError.value = null
  try {
    const [tripRes] = await Promise.all([getTrip(tripIdNum.value), loadManifest(1)])
    trip.value = tripRes
  } catch (e) {
    loadError.value = e instanceof ApiError ? e.message : 'Could not load the manifest. Try again.'
  } finally {
    loading.value = false
  }
}

onMounted(load)

useManifestChannel(
  () => tripIdNum.value,
  (event) => {
    liveUpdateNotice.value = LIVE_UPDATE_MESSAGES[event.type]
    void loadManifest()
  },
)

async function goToPage(page: number) {
  if (!meta.value || page < 1 || page > meta.value.pages) return
  manifestLoading.value = true
  try {
    await loadManifest(page)
  } catch (e) {
    loadError.value = e instanceof ApiError ? e.message : 'Could not load that page. Try again.'
  } finally {
    manifestLoading.value = false
  }
}

// --- Quick check-in bar + per-row shortcut ---

const referenceCodeInput = ref('')
const checkInPending = ref(false)
const checkInError = ref<string | null>(null)

async function submitCheckIn(code: string) {
  checkInError.value = null
  checkInPending.value = true
  const sentAt = Date.now()
  try {
    const res = await checkIn(tripIdNum.value, code)
    const checkedInAt = res.rows[0]?.booking.checked_in_at
    // The endpoint is idempotent — a re-check-in still succeeds. The only client-observable
    // signal that nothing actually changed is a checked_in_at that predates this request.
    if (checkedInAt && new Date(checkedInAt).getTime() < sentAt) {
      noopNotice.value = `${res.rows[0]?.full_name} was already checked in — no change made.`
    }
    referenceCodeInput.value = ''
    await loadManifest()
  } catch (e) {
    checkInError.value =
      e instanceof ApiError ? e.message : 'Could not check in that reference code. Try again.'
  } finally {
    checkInPending.value = false
  }
}

function onBarCheckIn() {
  if (referenceCodeInput.value.trim()) submitCheckIn(referenceCodeInput.value.trim())
}
function onRowCheckIn(row: ManifestRow) {
  submitCheckIn(row.booking.reference_code)
}

// --- Roster search — client-side, current page only (getManifest has no search param) ---

const rosterFilter = ref('')
const filteredRows = computed(() => {
  const q = rosterFilter.value.trim().toLowerCase()
  if (!q) return rows.value
  return rows.value.filter(
    (row) =>
      row.full_name.toLowerCase().includes(q) ||
      (row.seat_number ?? '').toLowerCase().includes(q) ||
      row.booking.reference_code.toLowerCase().includes(q),
  )
})

// --- Paid toggle ---
// A multi-seat booking shares one Payment row: only the first row holding a given payment.id
// gets the live switch, so staff can't record the same cash twice under one reference_code.
const primaryPaymentRow = computed(() => {
  const map = new Map<number, number>() // payment.id -> passenger_id
  for (const row of rows.value) {
    if (row.payment && !map.has(row.payment.id)) map.set(row.payment.id, row.passenger_id)
  }
  return map
})
function isPrimaryPaymentRow(row: ManifestRow): boolean {
  return !!row.payment && primaryPaymentRow.value.get(row.payment.id) === row.passenger_id
}
function primaryRowFor(row: ManifestRow): ManifestRow | undefined {
  if (!row.payment) return undefined
  const id = primaryPaymentRow.value.get(row.payment.id)
  return rows.value.find((r) => r.passenger_id === id)
}

const payingPaymentId = ref<number | null>(null)

async function onTogglePaid(row: ManifestRow) {
  if (!row.payment || payingPaymentId.value !== null) return
  payingPaymentId.value = row.payment.id
  const sentAt = Date.now()
  try {
    const nextCollected = row.payment.status !== 'collected'
    const updated = await updatePayment(row.payment.id, nextCollected)
    if (nextCollected && updated.collected_at && new Date(updated.collected_at).getTime() < sentAt) {
      noopNotice.value = `${row.full_name} was already marked paid — no change made.`
    }
    await loadManifest()
  } catch (e) {
    loadError.value = e instanceof ApiError ? e.message : 'Could not update payment. Try again.'
  } finally {
    payingPaymentId.value = null
  }
}
</script>

<template>
  <div>
    <BaseButton variant="secondary" size="sm" class="mb-4" @click="router.back()">
      <ArrowLeft class="w-4 h-4" />
      Back to Trips
    </BaseButton>

    <BaseToast
      v-if="loadError"
      variant="danger"
      :message="loadError"
      :dismissible="false"
      class="mb-4"
    />

    <p v-if="loading" class="text-sm text-muted">Loading…</p>

    <template v-else>
      <div class="flex items-center justify-between flex-wrap gap-3 mb-4 pb-4 border-b border-border">
        <div>
          <h1 class="font-display font-bold text-2xl uppercase tracking-wide">{{ trip?.route }}</h1>
          <p class="text-xs text-muted font-mono">
            {{ trip?.plate_number }} · {{ trip ? BUS_CLASS_LABELS[trip.bus_class] : '' }} · Departs
            {{ trip ? formatDateTime(trip.departure_at) : '—' }}
          </p>
        </div>
        <div class="flex items-center gap-4">
          <span
            class="inline-flex items-center gap-1.5 border px-2.5 py-1 text-[11px] font-display uppercase tracking-wide font-semibold"
            :class="
              boardingClosed
                ? 'border-border text-muted bg-surface'
                : 'border-success text-success bg-success/10'
            "
          >
            <Lock v-if="boardingClosed" class="w-3 h-3" />
            <span v-else class="w-2 h-2 rounded-full bg-success" />
            {{ boardingClosed ? 'Boarding Closed' : 'Live' }}
          </span>
          <div v-if="summary" class="text-right">
            <p
              class="font-mono text-sm font-semibold"
              :class="!boardingClosed && allCheckedIn ? 'text-success' : 'text-text'"
            >
              <Check v-if="!boardingClosed && allCheckedIn" class="w-3.5 h-3.5 inline" />
              {{ summary.checked_in }} / {{ summary.total_passengers }}
              <span class="text-muted font-normal">checked in</span>
            </p>
            <p class="text-[11px] text-muted font-mono">
              {{ summary.paid }} / {{ summary.total_passengers }} paid ·
              {{ summary.seats_booked }} / {{ summary.total_seats }} seats booked
            </p>
          </div>
        </div>
      </div>

      <BaseToast
        v-if="!boardingClosed && allCheckedIn"
        variant="success"
        message="All confirmed passengers are checked in. The check-in bar stays open — a booking made before departure can still arrive here."
        :dismissible="false"
        class="mb-4"
      />
      <BaseToast
        v-if="boardingClosed"
        variant="info"
        message="Boarding is closed for this trip. Check-in and payment collection are locked."
        :dismissible="false"
        class="mb-4"
      />
      <BaseToast
        v-if="liveUpdateNotice"
        variant="info"
        :message="liveUpdateNotice"
        class="mb-4"
        @dismiss="liveUpdateNotice = null"
      />

      <Empty
        v-if="summary?.total_passengers === 0 && !loadError"
        size="md"
        title="No bookings yet"
        message="No riders have booked this trip. The roster fills in automatically as bookings come in."
      >
        <template #icon="{ iconClass }">
          <Users :class="iconClass" />
        </template>
      </Empty>

      <template v-else>
        <div
          class="flex items-end gap-2 mb-4 flex-wrap"
          :class="checkInPending && 'opacity-60 pointer-events-none'"
          :aria-busy="checkInPending"
        >
          <BaseInput
            id="manifest-ref-code"
            v-model="referenceCodeInput"
            label="Reference code"
            placeholder="4XK-7QM-9"
            class="flex-1 min-w-[220px]"
            :disabled="checkInPending || boardingClosed"
            @keyup.enter="onBarCheckIn"
          />
          <BaseButton
            variant="primary"
            :disabled="boardingClosed"
            :loading="checkInPending"
            loading-text="Checking in…"
            @click="onBarCheckIn"
          >
            <Check class="w-4 h-4" />
            Check In
          </BaseButton>
          <BaseInput
            id="manifest-roster-search"
            v-model="rosterFilter"
            placeholder="Search roster…"
            class="w-48"
          >
            <template #leading="{ iconClass }">
              <Search :class="iconClass" class="w-3.5 h-3.5" />
            </template>
          </BaseInput>
        </div>
        <BaseToast
          v-if="checkInError"
          variant="danger"
          :message="checkInError"
          class="mb-4"
          @dismiss="checkInError = null"
        />
        <BaseToast
          v-if="noopNotice"
          variant="warning"
          :message="noopNotice"
          class="mb-4"
          @dismiss="noopNotice = null"
        />

        <div class="border border-border bg-surface overflow-x-auto">
          <table class="w-full text-sm">
            <thead>
              <tr class="border-b border-border text-left">
                <th class="font-display uppercase tracking-wider text-[11px] text-muted px-4 py-3">
                  Seat
                </th>
                <th class="font-display uppercase tracking-wider text-[11px] text-muted px-4 py-3">
                  Passenger
                </th>
                <th class="font-display uppercase tracking-wider text-[11px] text-muted px-4 py-3">
                  Ref Code
                </th>
                <th class="font-display uppercase tracking-wider text-[11px] text-muted px-4 py-3">
                  Status
                </th>
                <th class="font-display uppercase tracking-wider text-[11px] text-muted px-4 py-3">
                  Payment
                </th>
                <th class="px-4 py-3" />
              </tr>
            </thead>
            <tbody>
              <tr v-for="row in filteredRows" :key="row.passenger_id" class="border-b border-border last:border-b-0">
                <td class="px-4 py-3 font-mono text-xs">{{ row.seat_number ?? '—' }}</td>
                <td class="px-4 py-3">{{ row.full_name }}</td>
                <td class="px-4 py-3 font-mono text-xs">{{ row.booking.reference_code }}</td>
                <td class="px-4 py-3">
                  <span
                    class="inline-flex items-center gap-1 border px-2 py-0.5 text-[11px] font-medium"
                    :class="
                      row.booking.checked_in
                        ? 'border-primary text-primary bg-primary/10'
                        : 'border-accent text-accent bg-accent/10'
                    "
                  >
                    <Check v-if="row.booking.checked_in" class="w-3 h-3" />
                    {{ row.booking.checked_in ? 'Checked in' : 'Booked' }}
                  </span>
                </td>
                <td class="px-4 py-3">
                  <template v-if="!row.payment">—</template>
                  <button
                    v-else-if="!boardingClosed && isPrimaryPaymentRow(row)"
                    type="button"
                    role="switch"
                    :aria-checked="row.payment.status === 'collected'"
                    :aria-label="
                      row.payment.status === 'collected'
                        ? 'Mark payment not collected'
                        : 'Mark payment collected'
                    "
                    class="inline-flex items-center gap-2 min-h-[44px] px-1 -mx-1 focus:outline-none focus:ring-2 focus:ring-primary disabled:opacity-60"
                    :disabled="payingPaymentId === row.payment.id"
                    @click="onTogglePaid(row)"
                  >
                    <span
                      class="relative w-9 h-5 border shrink-0"
                      :class="
                        row.payment.status === 'collected'
                          ? 'border-primary bg-primary'
                          : 'border-border bg-surface'
                      "
                    >
                      <span
                        class="absolute top-0.5 w-3.5 h-3.5"
                        :class="row.payment.status === 'collected' ? 'right-0.5 bg-white' : 'left-0.5 bg-muted'"
                      />
                    </span>
                    <span
                      class="text-xs"
                      :class="row.payment.status === 'collected' ? 'text-primary font-medium' : 'text-muted'"
                    >
                      {{ row.payment.status === 'collected' ? 'Paid' : 'Unpaid' }}
                    </span>
                  </button>
                  <span
                    v-else
                    role="status"
                    class="inline-flex items-center gap-1.5 border px-2 py-1 text-[11px] font-medium"
                    :class="
                      row.payment.status === 'collected'
                        ? 'border-primary/40 bg-primary/5 text-primary/70'
                        : 'border-border bg-surface text-muted'
                    "
                  >
                    {{ row.payment.status === 'collected' ? 'Paid' : 'Unpaid' }}
                    <template v-if="!isPrimaryPaymentRow(row)"> via {{ primaryRowFor(row)?.seat_number }}</template>
                  </span>
                </td>
                <td class="px-4 py-3 text-right">
                  <BaseButton
                    v-if="!row.booking.checked_in && !boardingClosed"
                    variant="secondary"
                    size="sm"
                    :loading="checkInPending"
                    @click="onRowCheckIn(row)"
                  >
                    Check In
                  </BaseButton>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div v-if="meta && meta.pages > 1" class="flex items-center justify-between mt-3">
          <p class="text-[11px] text-muted">
            Showing page {{ meta.page }} of {{ meta.pages }} · {{ meta.count }} confirmed passengers
          </p>
          <div class="flex gap-2">
            <BaseButton
              variant="secondary"
              size="sm"
              :disabled="meta.page <= 1 || manifestLoading"
              @click="goToPage(meta.page - 1)"
            >
              Prev
            </BaseButton>
            <BaseButton
              variant="secondary"
              size="sm"
              :disabled="meta.page >= meta.pages || manifestLoading"
              @click="goToPage(meta.page + 1)"
            >
              Next
            </BaseButton>
          </div>
        </div>
      </template>
    </template>
  </div>
</template>
