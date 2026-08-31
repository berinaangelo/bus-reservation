<script setup lang="ts">
// Trips CRUD — same list+drawer shape as OperatorRoutesView.vue/OperatorFareRulesView.vue (local
// refs, no store). Two things set this resource apart: unlike FareRules, route_id is NOT
// immutable on edit (the controller explicitly supports changing it on update and recomputes
// arrival_at), so the Route picker stays enabled in both Add and Edit; and departure_at is
// entered via a datetime-local input that has to be converted to/from PH wall-clock time at the
// form boundary (see utils/phDateTime.ts) since arrival_at itself is always server-computed from
// the route's estimated_duration_minutes and only ever previewed here, never submitted.
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { CalendarClock, ClipboardList, Pencil, Plus, Trash2 } from '@lucide/vue'
import { listTrips, createTrip, updateTrip, deleteTrip } from '../../api/operator/trips'
import type { OperatorTripParams } from '../../api/operator/trips'
import { listRoutes } from '../../api/operator/routes'
import { listBusUnits } from '../../api/operator/busUnits'
import type { OperatorRoute, OperatorBusUnit } from '../../types/operator'
import type { OperatorTrip, BusClass, TripStatus } from '../../types/trip'
import { ApiError } from '../../api/types'
import type { SelectOption } from '../../types/ui'
import { isoToPhDateTimeLocal, phDateTimeLocalToIso } from '../../utils/phDateTime'
import { formatDateTime } from '../../utils/format'
import BaseButton from '../../components/ui/BaseButton.vue'
import BaseInput from '../../components/ui/BaseInput.vue'
import BaseSelect from '../../components/ui/BaseSelect.vue'
import BaseToast from '../../components/ui/BaseToast.vue'
import BaseDialog from '../../components/ui/BaseDialog.vue'
import BaseDrawer from '../../components/ui/BaseDrawer.vue'
import Empty from '../../components/ui/Empty.vue'

const BUS_CLASS_LABELS: Record<BusClass, string> = {
  ordinary: 'Ordinary',
  aircon: 'Aircon',
  deluxe: 'Deluxe',
  double_deck: 'Double-Deck',
}

const STATUS_LABELS: Record<TripStatus, string> = {
  scheduled: 'Scheduled',
  boarding: 'Boarding',
  departed: 'Departed',
  completed: 'Completed',
  cancelled: 'Cancelled',
}

const statusOptions: SelectOption<TripStatus>[] = (
  Object.keys(STATUS_LABELS) as TripStatus[]
).map((value) => ({ label: STATUS_LABELS[value], value }))

function routeLabel(route: OperatorRoute): string {
  return `${route.origin_terminal} → ${route.destination_terminal}`
}

function busUnitLabel(unit: OperatorBusUnit): string {
  return `${unit.plate_number} — ${BUS_CLASS_LABELS[unit.bus_class]}`
}

const router = useRouter()

const trips = ref<OperatorTrip[]>([])
const routes = ref<OperatorRoute[]>([])
const busUnits = ref<OperatorBusUnit[]>([])
const loading = ref(true)
const loadError = ref<string | null>(null)
const successMessage = ref<string | null>(null)

const routeOptions = computed<SelectOption<number>[]>(() =>
  routes.value.map((r) => ({ label: routeLabel(r), value: r.id })),
)
const routesById = computed(() => new Map(routes.value.map((r) => [r.id, r])))

// Deliberately NOT filtered to "units free during the chosen departure window" — see the
// mockup's own annotation in kos/decisions/ux/mockups/operator-dashboard.html (Trip CRUD
// section): no backend support exists for this (listBusUnits has no such param), and the
// double-booking check only really happens at save time via the bus_unit_not_double_booked
// model validation (surfaced as busUnitError below). Building a client-side approximation here
// would require fetching every trip per bus unit to compute overlaps — expensive and easy to
// get subtly wrong/misleading. Known gap, flagged not solved, same as the mockup itself flags it.
const busUnitOptions = computed<SelectOption<number>[]>(() =>
  busUnits.value.filter((u) => u.active).map((u) => ({ label: busUnitLabel(u), value: u.id })),
)

const drawerOpen = ref(false)
const editingId = ref<number | null>(null)

const routeId = ref<number | null>(null)
const routeError = ref<string | undefined>(undefined)

const busUnitId = ref<number | null>(null)
const busUnitError = ref<string | undefined>(undefined)

const departureLocal = ref('')
const departureError = ref<string | undefined>(undefined)

const status = ref<TripStatus>('scheduled')
const statusError = ref<string | undefined>(undefined)

const formError = ref<string | null>(null)
const submitting = ref(false)

const confirmingId = ref<number | null>(null)
const deletingId = ref<number | null>(null)

// Pure client-side preview — arrival_at is always server-computed, this is never submitted.
const estArrivalPreview = computed(() => {
  const route = routesById.value.get(routeId.value ?? -1)
  if (!route || !departureLocal.value || route.estimated_duration_minutes == null) return null
  const departureIso = phDateTimeLocalToIso(departureLocal.value)
  const arrivalMs = new Date(departureIso).getTime() + route.estimated_duration_minutes * 60_000
  return formatDateTime(new Date(arrivalMs).toISOString())
})

async function load() {
  loading.value = true
  loadError.value = null
  try {
    const [tripsRes, routesRes, busUnitsRes] = await Promise.all([
      listTrips(),
      listRoutes(),
      listBusUnits(),
    ])
    trips.value = tripsRes.trips
    routes.value = routesRes.routes
    busUnits.value = busUnitsRes.bus_units
  } catch (e) {
    loadError.value = e instanceof ApiError ? e.message : 'Could not load trips. Try again.'
  } finally {
    loading.value = false
  }
}

onMounted(load)

function resetForm() {
  routeId.value = null
  routeError.value = undefined
  busUnitId.value = null
  busUnitError.value = undefined
  departureLocal.value = ''
  departureError.value = undefined
  status.value = 'scheduled'
  statusError.value = undefined
  formError.value = null
}

function openAddDrawer() {
  editingId.value = null
  resetForm()
  drawerOpen.value = true
}

function openEditDrawer(trip: OperatorTrip) {
  editingId.value = trip.id
  resetForm()
  routeId.value = trip.route_id
  busUnitId.value = trip.bus_unit_id
  departureLocal.value = isoToPhDateTimeLocal(trip.departure_at)
  status.value = trip.status
  drawerOpen.value = true
}

function goToManifest(trip: OperatorTrip) {
  router.push({ name: 'trip-manifest', params: { tripId: trip.id } })
}

function validate(): boolean {
  routeError.value = routeId.value ? undefined : 'Select a route.'
  busUnitError.value = busUnitId.value ? undefined : 'Select a bus unit.'
  departureError.value = departureLocal.value ? undefined : 'Select a departure date and time.'
  statusError.value = status.value ? undefined : 'Select a status.'

  return (
    !routeError.value && !busUnitError.value && !departureError.value && !statusError.value
  )
}

async function onSubmit() {
  formError.value = null
  if (!validate()) return

  submitting.value = true
  try {
    const params: OperatorTripParams = {
      route_id: routeId.value!,
      bus_unit_id: busUnitId.value!,
      departure_at: phDateTimeLocalToIso(departureLocal.value),
      status: status.value,
    }
    if (editingId.value) {
      await updateTrip(editingId.value, params)
      successMessage.value = `Updated trip on ${routeLabel(routesById.value.get(routeId.value!)!)}.`
    } else {
      await createTrip(params)
      successMessage.value = `Scheduled trip on ${routeLabel(routesById.value.get(routeId.value!)!)}.`
    }
    drawerOpen.value = false
    await load()
  } catch (e) {
    if (e instanceof ApiError && e.fieldErrors) {
      routeError.value = e.fieldErrors.route_id?.[0]
      busUnitError.value = e.fieldErrors.bus_unit_id?.[0]
      departureError.value = e.fieldErrors.departure_at?.[0]
      statusError.value = e.fieldErrors.status?.[0]
      // arrival_at has no form field of its own (it isn't user-editable) — surface it as a
      // form-level error instead of trying to attach it to a field.
      const arrivalIssue = e.fieldErrors.arrival_at?.[0]
      if (!routeError.value && !busUnitError.value && !departureError.value && !statusError.value) {
        formError.value = arrivalIssue ?? e.message
      }
    } else {
      formError.value = e instanceof ApiError ? e.message : 'Something went wrong. Try again.'
    }
  } finally {
    submitting.value = false
  }
}

async function onDelete(trip: OperatorTrip) {
  deletingId.value = trip.id
  try {
    await deleteTrip(trip.id)
    confirmingId.value = null
    await load()
  } catch (e) {
    // A trip with existing bookings is blocked (dependent: :restrict_with_error), which comes
    // back as { errors: { bookings: [...] } } — no top-level `error` key, so ApiError.message
    // alone would just be the generic "Request failed" fallback. Pull the real message out of
    // fieldErrors first.
    if (e instanceof ApiError) {
      loadError.value = e.fieldErrors?.bookings?.[0] ?? e.message
    } else {
      loadError.value = 'Could not delete trip. Try again.'
    }
  } finally {
    deletingId.value = null
  }
}
</script>

<template>
  <div>
    <div class="flex items-center justify-between mb-5">
      <h1 class="font-display text-2xl font-bold">Trips</h1>
      <BaseButton variant="primary" size="sm" @click="openAddDrawer">
        <Plus class="w-3.5 h-3.5" />
        Add Trip
      </BaseButton>
    </div>

    <BaseToast
      v-if="successMessage"
      variant="success"
      :message="successMessage"
      class="mb-4"
      @dismiss="successMessage = null"
    />
    <BaseToast
      v-if="loadError"
      variant="danger"
      :message="loadError"
      :dismissible="false"
      class="mb-4"
    />

    <p v-if="loading" class="text-sm text-muted">Loading…</p>

    <Empty
      v-else-if="trips.length === 0 && !loadError"
      size="md"
      title="No trips scheduled"
      message="Schedule a departure on one of your routes so riders can find it in trip search."
    >
      <template #icon="{ iconClass }">
        <CalendarClock :class="iconClass" />
      </template>
      <template #action>
        <BaseButton variant="primary" size="sm" @click="openAddDrawer">Add Trip</BaseButton>
      </template>
    </Empty>

    <div v-else class="border border-border bg-surface overflow-x-auto">
      <table class="w-full text-sm">
        <thead>
          <tr class="border-b border-border text-left">
            <th class="font-display uppercase tracking-wider text-[11px] text-muted px-4 py-3">
              Route
            </th>
            <th class="font-display uppercase tracking-wider text-[11px] text-muted px-4 py-3">
              Bus Unit
            </th>
            <th class="font-display uppercase tracking-wider text-[11px] text-muted px-4 py-3">
              Departure
            </th>
            <th class="font-display uppercase tracking-wider text-[11px] text-muted px-4 py-3">
              Status
            </th>
            <th class="px-4 py-3" />
          </tr>
        </thead>
        <tbody>
          <template v-for="trip in trips" :key="trip.id">
            <tr class="border-b border-border last:border-b-0">
              <td class="px-4 py-3">{{ trip.route }}</td>
              <td class="px-4 py-3 font-mono text-xs">
                {{ trip.plate_number }} — {{ BUS_CLASS_LABELS[trip.bus_class] }}
              </td>
              <td class="px-4 py-3 font-mono text-xs">{{ formatDateTime(trip.departure_at) }}</td>
              <td class="px-4 py-3">{{ STATUS_LABELS[trip.status] }}</td>
              <td class="px-4 py-3 text-right">
                <span v-if="confirmingId !== trip.id" class="inline-flex gap-2">
                  <BaseButton
                    variant="secondary"
                    size="sm"
                    icon-only
                    aria-label="View manifest"
                    @click="goToManifest(trip)"
                  >
                    <ClipboardList class="w-4 h-4" />
                  </BaseButton>
                  <BaseButton
                    variant="secondary"
                    size="sm"
                    icon-only
                    aria-label="Edit trip"
                    @click="openEditDrawer(trip)"
                  >
                    <Pencil class="w-4 h-4" />
                  </BaseButton>
                  <BaseButton
                    variant="secondary"
                    size="sm"
                    icon-only
                    aria-label="Delete trip"
                    @click="confirmingId = trip.id"
                  >
                    <Trash2 class="w-4 h-4" />
                  </BaseButton>
                </span>
              </td>
            </tr>
            <tr v-if="confirmingId === trip.id" class="bg-danger/5 border-b border-border">
              <td colspan="5" class="px-3 py-3">
                <BaseDialog
                  layout="inline"
                  variant="danger"
                  :message="`Delete the ${formatDateTime(trip.departure_at)} trip? This can't be undone.`"
                  confirm-label="Yes, Delete"
                  cancel-label="Keep"
                  :loading="deletingId === trip.id"
                  @confirm="onDelete(trip)"
                  @cancel="confirmingId = null"
                />
              </td>
            </tr>
          </template>
        </tbody>
      </table>
    </div>

    <BaseDrawer
      v-model="drawerOpen"
      :title="editingId ? 'Edit Trip' : 'Add Trip'"
      :persistent="submitting"
    >
      <form class="space-y-4" @submit.prevent="onSubmit">
        <BaseToast
          v-if="formError"
          variant="danger"
          :message="formError"
          :dismissible="false"
          class="mb-1"
        />

        <BaseSelect
          id="trip-route"
          v-model="routeId"
          :options="routeOptions"
          :disabled="submitting"
          :error="routeError"
          label="Route"
          placeholder="Select route…"
        />

        <BaseSelect
          id="trip-bus-unit"
          v-model="busUnitId"
          :options="busUnitOptions"
          :disabled="submitting"
          :error="busUnitError"
          label="Bus unit"
          placeholder="Select bus unit…"
        />

        <BaseInput
          id="trip-departure"
          v-model="departureLocal"
          type="datetime-local"
          label="Departure"
          :disabled="submitting"
          :error="departureError"
        />

        <div class="border border-border bg-surface px-3 py-2 text-xs text-muted">
          Est. arrival: <span class="font-mono">{{ estArrivalPreview ?? '—' }}</span>
          <span class="text-muted/70"> (auto, from route duration)</span>
        </div>

        <BaseSelect
          id="trip-status"
          v-model="status"
          :options="statusOptions"
          :disabled="submitting"
          :error="statusError"
          label="Status"
          placeholder="Select status…"
        />

        <div class="flex gap-3 pt-2">
          <BaseButton
            type="submit"
            variant="primary"
            class="flex-1"
            :loading="submitting"
            loading-text="Saving…"
          >
            Save Trip
          </BaseButton>
          <BaseButton
            type="button"
            variant="secondary"
            :disabled="submitting"
            @click="drawerOpen = false"
          >
            Cancel
          </BaseButton>
        </div>
      </form>
    </BaseDrawer>
  </div>
</template>
