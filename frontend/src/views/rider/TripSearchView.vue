<script setup lang="ts">
// Trip Search — first rider touchpoint. Built from the chosen Route Line layout in
// kos/decisions/ux/mockups/trip-search.html (laws-of-ux passed), including its loading and
// zero-results states. Two departures from the literal mockup, both deliberate:
//   1. The mockup's inner "TS — Terminal Signal" branding row is dropped — RiderLayout already
//      renders the app's real header one level up (see components/layout/AppHeader.vue).
//   2. The mockup's border-2 border-primary card frame is that file's own "chosen option" badge,
//      not intended production styling — using plain border-border.
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { MapPin, Calendar, Search, ArrowLeftRight } from '@lucide/vue'
import BaseAutocomplete from '../../components/ui/BaseAutocomplete.vue'
import BaseInput from '../../components/ui/BaseInput.vue'
import BaseButton from '../../components/ui/BaseButton.vue'
import BaseToast from '../../components/ui/BaseToast.vue'
import Empty from '../../components/ui/Empty.vue'
import { searchTrips } from '../../api/trips'
import { ApiError } from '../../api/types'
import { loadTerminals, todayLocalISODate } from '../../utils/tripSearchForm'

const router = useRouter()

const originId = ref<number | null>(null)
const originQuery = ref('')
const originError = ref<string | undefined>(undefined)

const destinationId = ref<number | null>(null)
const destinationQuery = ref('')
const destinationError = ref<string | undefined>(undefined)

const date = ref(todayLocalISODate())

const submitting = ref(false)
const submitError = ref<string | null>(null)
const noResults = ref<{ origin: string; destination: string; date: string } | null>(null)

function swap() {
  ;[originId.value, destinationId.value] = [destinationId.value, originId.value]
  ;[originQuery.value, destinationQuery.value] = [destinationQuery.value, originQuery.value]
  ;[originError.value, destinationError.value] = [destinationError.value, originError.value]
}

function validate(): boolean {
  originError.value = originId.value ? undefined : 'Select an origin terminal.'
  destinationError.value = destinationId.value ? undefined : 'Select a destination terminal.'
  if (!originError.value && !destinationError.value && originId.value === destinationId.value) {
    destinationError.value = "Origin and destination can't be the same."
  }
  return !originError.value && !destinationError.value
}

async function onSubmit() {
  submitError.value = null
  noResults.value = null
  if (!validate() || !date.value) return

  submitting.value = true
  try {
    const response = await searchTrips({
      origin_terminal_id: originId.value!,
      destination_terminal_id: destinationId.value!,
      date: date.value,
    })

    if (response.trips.length === 0) {
      noResults.value = {
        origin: originQuery.value,
        destination: destinationQuery.value,
        date: date.value,
      }
    } else {
      router.push({
        name: 'trip-search-results',
        query: {
          origin_terminal_id: String(originId.value),
          destination_terminal_id: String(destinationId.value),
          date: date.value,
          // Passed along purely as display text so the results screen's header/empty state
          // doesn't need its own terminal lookup — GET /api/v1/terminals only supports
          // search-by-text, not fetch-by-id. Results view falls back to a returned trip's own
          // origin_terminal/destination_terminal if these are absent (e.g. a bookmarked URL).
          origin_name: originQuery.value,
          destination_name: destinationQuery.value,
        },
      })
    }
  } catch (e) {
    submitError.value = e instanceof ApiError ? e.message : 'Something went wrong. Try again.'
  } finally {
    submitting.value = false
  }
}

function clearSearch() {
  originId.value = null
  originQuery.value = ''
  originError.value = undefined
  destinationId.value = null
  destinationQuery.value = ''
  destinationError.value = undefined
  date.value = todayLocalISODate()
  noResults.value = null
}
</script>

<template>
  <div>
    <BaseToast
      v-if="submitError"
      variant="danger"
      :message="submitError"
      :dismissible="false"
      class="mb-4"
    />

    <form
      class="border border-border bg-surface p-5 sm:p-6 transition-opacity duration-150 motion-reduce:transition-none"
      :class="{ 'opacity-60 pointer-events-none': submitting }"
      :aria-busy="submitting"
      @submit.prevent="onSubmit"
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
            :disabled="submitting"
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
          :disabled="submitting"
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
            :disabled="submitting"
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
          :disabled="submitting"
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
          :loading="submitting"
          loading-text="Searching…"
        >
          <Search class="w-4 h-4" />
          Search trips
        </BaseButton>
      </div>
    </form>

    <Empty
      v-if="noResults"
      size="lg"
      title="No trips found"
      :message="`${noResults.origin} → ${noResults.destination} · ${noResults.date} has no available trips. Try a different date or route.`"
      class="mt-4"
    >
      <template #icon="{ iconClass }">
        <Search :class="iconClass" />
      </template>
      <template #action>
        <BaseButton variant="secondary" @click="clearSearch">Clear search</BaseButton>
      </template>
    </Empty>

    <!-- Idle state, before any search has been submitted -- not in the mockup (which only covers
    the form itself plus its loading/zero-results states), but the same shape as those states so
    the page doesn't just end on empty space below the form. -->
    <Empty
      v-else
      size="lg"
      title="Search for a trip"
      message="Enter an origin, destination, and departure date above to see available trips."
      class="mt-4"
    >
      <template #icon="{ iconClass }">
        <Search :class="iconClass" />
      </template>
    </Empty>
  </div>
</template>
