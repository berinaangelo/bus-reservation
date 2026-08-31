<script setup lang="ts">
// Trip Search Results — built from the chosen Timeline Rail layout (Option C) in
// kos/decisions/ux/mockups/trip-search-results.html, including its Loading-more and
// End-of-results states. Two departures from the literal mockup, both deliberate, mirroring the
// same two TripSearchView.vue already made from its own mockup:
//   1. The mockup's inner "TS — Terminal Signal" branding row is dropped — RiderLayout already
//      renders the app's real header one level up.
//   2. The mockup's border-2 border-primary "chosen option" card frame isn't production
//      styling — using plain border-border.
// A third, necessary deviation: the mockup's static "4 trips found" assumes a known total, but
// cursor pagination has no cheap total count (see kos/decisions/rails-pagination-and-batch-
// export-processing.md) — showing one while has_more is still true would be a lie. See
// summaryLabel below.
// A fourth addition beyond the mockup (which only has an end-of-list "Modify search" button):
// the same Route Line search bar TripSearchView.vue uses is embedded here too, prefilled with
// the current search, so a rider can adjust and re-run without leaving this screen. It drives
// off local reactive state rather than route.query directly (re-navigating to the same route
// name doesn't remount the component, so a frozen read of route.query at setup wouldn't react to
// a second in-place search); router.replace after a re-search just keeps the URL shareable.
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import {
  Clock,
  ChevronDown,
  CircleCheck,
  Search,
  MapPin,
  Calendar,
  ArrowLeftRight,
} from '@lucide/vue'
import BaseAutocomplete from '../../components/ui/BaseAutocomplete.vue'
import BaseInput from '../../components/ui/BaseInput.vue'
import BaseButton from '../../components/ui/BaseButton.vue'
import BaseToast from '../../components/ui/BaseToast.vue'
import Empty from '../../components/ui/Empty.vue'
import { searchTrips } from '../../api/trips'
import { useCheckoutStore } from '../../stores/checkout'
import { ApiError } from '../../api/types'
import { loadTerminals, todayLocalISODate } from '../../utils/tripSearchForm'
import { formatFare } from '../../utils/format'
import type { BusClass, Trip } from '../../types/trip'

type Bucket = 'morning' | 'afternoon' | 'evening'
interface TripGroup {
  bucket: Bucket
  trips: Trip[]
}

const BUCKET_LABELS: Record<Bucket, string> = {
  morning: 'Morning',
  afternoon: 'Afternoon',
  evening: 'Evening',
}

const BUS_CLASS_LABELS: Record<BusClass, string> = {
  ordinary: 'Ordinary',
  aircon: 'Aircon',
  deluxe: 'Deluxe',
  double_deck: 'Double-Deck',
}
const PREMIUM_CLASSES: BusClass[] = ['deluxe', 'double_deck']

function asString(value: unknown): string | undefined {
  return typeof value === 'string' && value.length > 0 ? value : undefined
}

// Manila-local hour, read off the ISO8601 string's own timezone rather than the viewer's browser
// timezone — same care TripSearchView's todayLocalISODate() takes for the date field.
// hourCycle: 'h23' is required, not just hour12: false — some engines format en-US midnight as
// "24" under hour12: false unless h23 is set explicitly.
function manilaHour(iso: string): number {
  const formatted = new Intl.DateTimeFormat('en-US', {
    timeZone: 'Asia/Manila',
    hour: '2-digit',
    hourCycle: 'h23',
  }).format(new Date(iso))
  return Number(formatted)
}

function bucketFor(iso: string): Bucket {
  const hour = manilaHour(iso)
  if (hour < 12) return 'morning'
  if (hour < 18) return 'afternoon'
  return 'evening'
}

function formatTime(iso: string): string {
  return new Intl.DateTimeFormat('en-US', {
    timeZone: 'Asia/Manila',
    hour: 'numeric',
    minute: '2-digit',
    hour12: true,
  }).format(new Date(iso))
}

function formatDuration(departureIso: string, arrivalIso: string): string {
  const minutes = Math.round(
    (new Date(arrivalIso).getTime() - new Date(departureIso).getTime()) / 60_000,
  )
  const hours = Math.floor(minutes / 60)
  const mins = minutes % 60
  return `${hours}h ${String(mins).padStart(2, '0')}m`
}

function formatDate(isoDate: string): string {
  return new Intl.DateTimeFormat('en-US', {
    timeZone: 'UTC',
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  }).format(new Date(`${isoDate}T00:00:00Z`))
}

function isPremium(busClass: BusClass): boolean {
  return PREMIUM_CLASSES.includes(busClass)
}

// Thresholds aren't specified by the mockup beyond its examples (12/18 -> green, 3 -> amber,
// 0 -> red) -- picked 5 as the low-availability cutoff.
function seatStatus(seatsAvailable: number): { colorClass: string; label: string } {
  if (seatsAvailable <= 0) return { colorClass: 'bg-danger', label: 'Sold out' }
  if (seatsAvailable <= 5) return { colorClass: 'bg-warning', label: `${seatsAvailable} left` }
  return { colorClass: 'bg-success', label: `${seatsAvailable} left` }
}

const route = useRoute()
const router = useRouter()
const checkoutStore = useCheckoutStore()

const initialOriginId = asString(route.query.origin_terminal_id)
const initialDestinationId = asString(route.query.destination_terminal_id)
const initialDate = asString(route.query.date)
const validParams = Boolean(initialOriginId && initialDestinationId && initialDate)

if (!validParams) {
  router.replace({ name: 'trip-search' })
}

// Search bar state — seeded from the URL, then the single source of truth for every fetch
// (initial load, load-more, and a re-search from this bar). See header comment for why this
// can't just re-read route.query reactively.
const originId = ref<number | null>(initialOriginId ? Number(initialOriginId) : null)
const originQuery = ref(asString(route.query.origin_name) ?? '')
const originError = ref<string | undefined>(undefined)

const destinationId = ref<number | null>(initialDestinationId ? Number(initialDestinationId) : null)
const destinationQuery = ref(asString(route.query.destination_name) ?? '')
const destinationError = ref<string | undefined>(undefined)

const date = ref(initialDate ?? todayLocalISODate())

const trips = ref<Trip[]>([])
const cursor = ref<string | undefined>(undefined)
const hasMore = ref(false)
const loading = ref(false)
const loadingMore = ref(false)
const error = ref<string | null>(null)
const initialLoadDone = ref(false)

const originName = computed(() => originQuery.value || trips.value[0]?.origin_terminal || '')
const destinationName = computed(
  () => destinationQuery.value || trips.value[0]?.destination_terminal || '',
)
const formattedDate = computed(() => (date.value ? formatDate(date.value) : ''))

const summaryLabel = computed(() => {
  const n = trips.value.length
  const noun = n === 1 ? 'trip' : 'trips'
  return hasMore.value ? `${n} ${noun} shown so far` : `${n} ${noun} found`
})

// Trips arrive pre-sorted ascending by departure_at (the keyset order) and a "Load more" page
// only ever appends after what's already loaded, so re-deriving groups from the flat list on
// every change is equivalent to tracking "the last-rendered bucket" by hand — a bucket can only
// ever start once, never reopen above earlier rows. See the mockup's own pagination note.
const groupedTrips = computed<TripGroup[]>(() => {
  const groups: TripGroup[] = []
  for (const trip of trips.value) {
    const bucket = bucketFor(trip.departure_at)
    const last = groups[groups.length - 1]
    if (last && last.bucket === bucket) {
      last.trips.push(trip)
    } else {
      groups.push({ bucket, trips: [trip] })
    }
  }
  return groups
})

function swap() {
  ;[originId.value, destinationId.value] = [destinationId.value, originId.value]
  ;[originQuery.value, destinationQuery.value] = [destinationQuery.value, originQuery.value]
  ;[originError.value, destinationError.value] = [destinationError.value, originError.value]
}

function validateSearch(): boolean {
  originError.value = originId.value ? undefined : 'Select an origin terminal.'
  destinationError.value = destinationId.value ? undefined : 'Select a destination terminal.'
  if (!originError.value && !destinationError.value && originId.value === destinationId.value) {
    destinationError.value = "Origin and destination can't be the same."
  }
  return !originError.value && !destinationError.value
}

async function fetchPage(nextCursor?: string) {
  const response = await searchTrips({
    origin_terminal_id: originId.value!,
    destination_terminal_id: destinationId.value!,
    date: date.value,
    cursor: nextCursor,
  })
  trips.value.push(...response.trips)
  cursor.value = response.meta.next_cursor ?? undefined
  hasMore.value = response.meta.has_more
}

async function loadInitial() {
  loading.value = true
  error.value = null
  try {
    await fetchPage()
  } catch (e) {
    error.value = e instanceof ApiError ? e.message : 'Something went wrong. Try again.'
  } finally {
    loading.value = false
    initialLoadDone.value = true
  }
}

async function loadMore() {
  loadingMore.value = true
  error.value = null
  try {
    await fetchPage(cursor.value)
  } catch (e) {
    error.value = e instanceof ApiError ? e.message : 'Something went wrong. Try again.'
  } finally {
    loadingMore.value = false
  }
}

async function onSearchSubmit() {
  error.value = null
  if (!validateSearch() || !date.value) return

  trips.value = []
  cursor.value = undefined
  hasMore.value = false
  initialLoadDone.value = false

  // Keeps the URL shareable/bookmarkable; doesn't drive the fetch itself (see header comment).
  router.replace({
    name: 'trip-search-results',
    query: {
      origin_terminal_id: String(originId.value),
      destination_terminal_id: String(destinationId.value),
      date: date.value,
      origin_name: originQuery.value,
      destination_name: destinationQuery.value,
    },
  })

  await loadInitial()
}

function selectTrip(trip: Trip) {
  if (trip.seats_available === 0) return
  checkoutStore.startCheckout(trip)
  router.push({ name: 'seat-selection', params: { tripId: String(trip.id) } })
}

function modifySearch() {
  router.push({ name: 'trip-search' })
}

onMounted(() => {
  if (validParams) loadInitial()
})
</script>

<template>
  <div>
    <BaseToast v-if="error" variant="danger" :message="error" :dismissible="false" class="mb-4" />

    <form
      class="border border-border bg-surface p-5 sm:p-6 mb-4 transition-opacity duration-150 motion-reduce:transition-none"
      :class="{ 'opacity-60 pointer-events-none': loading }"
      :aria-busy="loading"
      @submit.prevent="onSearchSubmit"
    >
      <div
        class="relative flex flex-col sm:flex-row sm:items-end justify-between gap-4 sm:gap-8 mb-6"
      >
        <div
          class="hidden sm:block absolute left-[16%] right-[16%] top-[7px] border-t-2 border-dashed border-border"
          aria-hidden="true"
        />

        <div class="relative z-10 flex-1 min-w-0">
          <div class="flex items-center gap-2 mb-2">
            <span class="w-3 h-3 rounded-full bg-primary shrink-0" aria-hidden="true" />
            <span class="font-display uppercase tracking-wider text-[11px] text-muted">From</span>
          </div>
          <BaseAutocomplete
            v-model="originId"
            v-model:query="originQuery"
            :loader="loadTerminals"
            :disabled="loading"
            :error="originError"
            placeholder="Origin terminal"
          >
            <template #leading="{ iconClass }">
              <MapPin :class="iconClass" class="w-4 h-4 shrink-0" />
            </template>
          </BaseAutocomplete>
        </div>

        <BaseButton
          type="button"
          icon-only
          aria-label="Swap origin and destination"
          class="self-center sm:self-end"
          :disabled="loading"
          @click="swap"
        >
          <ArrowLeftRight class="w-5 h-5 rotate-90 sm:rotate-0" />
        </BaseButton>

        <div class="relative z-10 flex-1 min-w-0">
          <div class="flex items-center gap-2 mb-2">
            <span class="w-3 h-3 rounded-full bg-primary shrink-0" aria-hidden="true" />
            <span class="font-display uppercase tracking-wider text-[11px] text-muted">To</span>
          </div>
          <BaseAutocomplete
            v-model="destinationId"
            v-model:query="destinationQuery"
            :loader="loadTerminals"
            :disabled="loading"
            :error="destinationError"
            placeholder="Destination terminal"
          >
            <template #leading="{ iconClass }">
              <MapPin :class="iconClass" class="w-4 h-4 shrink-0" />
            </template>
          </BaseAutocomplete>
        </div>
      </div>

      <div class="flex flex-col sm:flex-row gap-3">
        <BaseInput
          v-model="date"
          type="date"
          label="Departure date"
          :min="todayLocalISODate()"
          :disabled="loading"
          required
          class="flex-1"
        >
          <template #leading="{ iconClass }">
            <Calendar :class="iconClass" class="w-4 h-4 shrink-0" />
          </template>
        </BaseInput>
        <BaseButton
          type="submit"
          variant="primary"
          class="sm:w-56"
          :loading="loading"
          loading-text="Searching…"
        >
          <Search class="w-4 h-4" />
          Search trips
        </BaseButton>
      </div>
    </form>

    <div
      v-if="loading"
      class="border border-border bg-background p-8 flex justify-center"
      aria-busy="true"
    >
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

    <Empty
      v-else-if="initialLoadDone && trips.length === 0"
      size="lg"
      title="No trips found"
      :message="`${originName} → ${destinationName} · ${formattedDate} has no available trips. Try a different date or route.`"
    >
      <template #icon="{ iconClass }">
        <Search :class="iconClass" />
      </template>
      <template #action>
        <BaseButton variant="secondary" @click="modifySearch">Modify search</BaseButton>
      </template>
    </Empty>

    <div v-else-if="trips.length > 0" class="border border-border bg-background p-4 sm:p-8">
      <div class="flex items-center justify-between gap-3 mb-6 flex-wrap">
        <p class="text-sm">
          <span class="font-medium">{{ originName }} → {{ destinationName }}</span>
          <span class="text-muted">
            · <span class="font-mono tabular-nums">{{ formattedDate }}</span> · {{ summaryLabel }}
          </span>
        </p>
      </div>

      <div class="relative">
        <div
          class="absolute left-4 top-2 bottom-2 border-l-2 border-dashed border-border"
          aria-hidden="true"
        />

        <template v-for="group in groupedTrips" :key="group.bucket">
          <div class="relative flex items-center gap-2 mb-3">
            <div class="w-8 shrink-0 flex justify-center">
              <Clock class="w-4 h-4 text-muted bg-background relative z-10" />
            </div>
            <span class="font-display uppercase tracking-wider text-xs text-muted">{{
              BUCKET_LABELS[group.bucket]
            }}</span>
          </div>

          <div
            v-for="trip in group.trips"
            :key="trip.id"
            class="relative flex gap-2 mb-4 last:mb-0"
          >
            <div class="w-8 shrink-0 flex justify-center pt-4">
              <span
                class="w-3 h-3 rounded-full border-2 border-background relative z-10 shrink-0"
                :class="trip.seats_available > 0 ? 'bg-primary' : 'bg-danger'"
                aria-hidden="true"
              />
            </div>
            <div
              class="flex-1 border border-border bg-surface p-4 flex flex-col sm:flex-row sm:items-center gap-3"
              :class="{ 'opacity-70': trip.seats_available === 0 }"
            >
              <div class="sm:w-40 shrink-0">
                <p class="font-medium text-base leading-tight">{{ trip.operator }}</p>
                <span
                  class="inline-flex items-center gap-1 px-2 py-0.5 mt-1 font-display uppercase tracking-wide text-[11px] font-semibold"
                  :class="
                    isPremium(trip.bus_class)
                      ? 'border border-secondary bg-secondary/10 text-secondary'
                      : 'border border-border text-muted'
                  "
                >
                  {{ BUS_CLASS_LABELS[trip.bus_class] }}
                </span>
              </div>

              <div class="flex-1">
                <p class="font-mono tabular-nums text-lg font-medium leading-tight">
                  {{ formatTime(trip.departure_at) }}
                  <span class="text-sm text-muted">→ {{ formatTime(trip.arrival_at) }}</span>
                </p>
                <p class="text-xs text-muted">
                  {{ formatDuration(trip.departure_at, trip.arrival_at) }}
                </p>
              </div>

              <div class="flex items-center gap-4 sm:gap-6">
                <div class="flex items-center gap-1.5">
                  <span
                    class="w-2 h-2 rounded-full shrink-0"
                    :class="seatStatus(trip.seats_available).colorClass"
                    aria-hidden="true"
                  />
                  <span
                    class="text-xs font-mono tabular-nums"
                    :class="trip.seats_available === 0 ? 'text-danger' : 'text-muted'"
                  >
                    {{ seatStatus(trip.seats_available).label }}
                  </span>
                </div>
                <p
                  class="font-mono tabular-nums text-lg font-semibold"
                  :class="trip.seats_available === 0 ? 'text-muted' : 'text-accent'"
                >
                  {{ formatFare(trip.fare) }}
                </p>
                <BaseButton
                  size="sm"
                  :disabled="trip.seats_available === 0"
                  @click="selectTrip(trip)"
                >
                  {{ trip.seats_available === 0 ? 'Sold out' : 'Select' }}
                </BaseButton>
              </div>
            </div>
          </div>
        </template>
      </div>

      <div v-if="hasMore" class="flex justify-center mt-6">
        <BaseButton
          variant="secondary"
          :loading="loadingMore"
          loading-text="Loading…"
          @click="loadMore"
        >
          Load more trips
          <ChevronDown class="w-4 h-4" />
        </BaseButton>
      </div>
      <div
        v-else
        class="flex flex-col items-center text-center gap-2 mt-10 pt-8 border-t-2 border-border"
      >
        <CircleCheck class="w-6 h-6 text-muted" aria-hidden="true" />
        <p class="text-sm text-muted">
          That's all trips for
          <span class="font-medium text-text">{{ originName }} → {{ destinationName }}</span>
          on <span class="font-mono tabular-nums">{{ formattedDate }}</span
          >.
        </p>
        <BaseButton variant="secondary" class="mt-1" @click="modifySearch"
          >Modify search</BaseButton
        >
      </div>
    </div>
  </div>
</template>
