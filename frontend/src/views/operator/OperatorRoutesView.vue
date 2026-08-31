<script setup lang="ts">
// Routes CRUD — dependency root for the operator admin build-out (Fare Rules and Trips both need
// a route picker). Built from kos/decisions/ux/mockups/operator-dashboard.html's Sidebar + Table
// Route CRUD states (Add/Edit drawer, validation error, delete confirm, empty list), same
// list+drawer shape as OperatorStaffView.vue. One deliberate deviation from the mockup: the
// "Active (visible in trip search)" checkbox/status badge is dropped — the routes table has no
// `active` column and OperatorRoute/OperatorRouteParams carry no such field, so it would be
// non-functional. Delete confirm follows the mockup's own layout (a dedicated table row) rather
// than OperatorStaffView's actions-cell swap, since that's the pattern the mockup specifies here.
import { onMounted, ref } from 'vue'
import { MapPin, Pencil, Plus, Route as RouteIcon, Trash2 } from '@lucide/vue'
import { listRoutes, createRoute, updateRoute, deleteRoute } from '../../api/operator/routes'
import type { OperatorRouteParams } from '../../api/operator/routes'
import type { OperatorRoute } from '../../types/operator'
import { ApiError } from '../../api/types'
import { loadTerminals } from '../../utils/tripSearchForm'
import { formatMinutes } from '../../utils/format'
import BaseButton from '../../components/ui/BaseButton.vue'
import BaseInput from '../../components/ui/BaseInput.vue'
import BaseAutocomplete from '../../components/ui/BaseAutocomplete.vue'
import BaseToast from '../../components/ui/BaseToast.vue'
import BaseDialog from '../../components/ui/BaseDialog.vue'
import BaseDrawer from '../../components/ui/BaseDrawer.vue'
import Empty from '../../components/ui/Empty.vue'

const routes = ref<OperatorRoute[]>([])
const loading = ref(true)
const loadError = ref<string | null>(null)
const successMessage = ref<string | null>(null)

const drawerOpen = ref(false)
const editingId = ref<number | null>(null)

const originId = ref<number | null>(null)
const originQuery = ref('')
const originError = ref<string | undefined>(undefined)

const destinationId = ref<number | null>(null)
const destinationQuery = ref('')
const destinationError = ref<string | undefined>(undefined)

const distanceKm = ref('')
const distanceError = ref<string | undefined>(undefined)

const durationMinutes = ref('')
const durationError = ref<string | undefined>(undefined)

const formError = ref<string | null>(null)
const submitting = ref(false)

const confirmingId = ref<number | null>(null)
const deletingId = ref<number | null>(null)

async function load() {
  loading.value = true
  loadError.value = null
  try {
    const res = await listRoutes()
    routes.value = res.routes
  } catch (e) {
    loadError.value = e instanceof ApiError ? e.message : 'Could not load routes. Try again.'
  } finally {
    loading.value = false
  }
}

onMounted(load)

function resetForm() {
  originId.value = null
  originQuery.value = ''
  originError.value = undefined
  destinationId.value = null
  destinationQuery.value = ''
  destinationError.value = undefined
  distanceKm.value = ''
  distanceError.value = undefined
  durationMinutes.value = ''
  durationError.value = undefined
  formError.value = null
}

function openAddDrawer() {
  editingId.value = null
  resetForm()
  drawerOpen.value = true
}

function openEditDrawer(route: OperatorRoute) {
  editingId.value = route.id
  resetForm()
  originId.value = route.origin_terminal_id
  originQuery.value = route.origin_terminal
  destinationId.value = route.destination_terminal_id
  destinationQuery.value = route.destination_terminal
  distanceKm.value = String(route.distance_km)
  durationMinutes.value = String(route.estimated_duration_minutes)
  drawerOpen.value = true
}

function validate(): boolean {
  originError.value = originId.value ? undefined : 'Select an origin terminal.'
  destinationError.value = destinationId.value ? undefined : 'Select a destination terminal.'
  if (!originError.value && !destinationError.value && originId.value === destinationId.value) {
    destinationError.value = 'Origin and destination must be different.'
  }

  const distance = Number(distanceKm.value)
  distanceError.value =
    distanceKm.value.trim() && Number.isFinite(distance) && distance > 0
      ? undefined
      : 'Must be greater than 0.'

  const duration = Number(durationMinutes.value)
  durationError.value =
    durationMinutes.value.trim() && Number.isInteger(duration) && duration > 0
      ? undefined
      : 'Must be a whole number greater than 0.'

  return (
    !originError.value && !destinationError.value && !distanceError.value && !durationError.value
  )
}

async function onSubmit() {
  formError.value = null
  if (!validate()) return

  const params: OperatorRouteParams = {
    origin_terminal_id: originId.value!,
    destination_terminal_id: destinationId.value!,
    distance_km: Number(distanceKm.value),
    estimated_duration_minutes: Number(durationMinutes.value),
  }

  submitting.value = true
  try {
    if (editingId.value) {
      await updateRoute(editingId.value, params)
      successMessage.value = `Updated ${originQuery.value} → ${destinationQuery.value}.`
    } else {
      await createRoute(params)
      successMessage.value = `Added ${originQuery.value} → ${destinationQuery.value}.`
    }
    drawerOpen.value = false
    await load()
  } catch (e) {
    if (e instanceof ApiError && e.fieldErrors) {
      originError.value = e.fieldErrors.origin_terminal_id?.[0]
      destinationError.value = e.fieldErrors.destination_terminal_id?.[0]
      distanceError.value = e.fieldErrors.distance_km?.[0]
      durationError.value = e.fieldErrors.estimated_duration_minutes?.[0]
      if (
        !originError.value &&
        !destinationError.value &&
        !distanceError.value &&
        !durationError.value
      ) {
        formError.value = e.message
      }
    } else {
      formError.value = e instanceof ApiError ? e.message : 'Something went wrong. Try again.'
    }
  } finally {
    submitting.value = false
  }
}

async function onDelete(route: OperatorRoute) {
  deletingId.value = route.id
  try {
    await deleteRoute(route.id)
    confirmingId.value = null
    await load()
  } catch (e) {
    loadError.value = e instanceof ApiError ? e.message : 'Could not delete route. Try again.'
  } finally {
    deletingId.value = null
  }
}
</script>

<template>
  <div>
    <div class="flex items-center justify-between mb-5">
      <h1 class="font-display text-2xl font-bold">Routes</h1>
      <BaseButton variant="primary" size="sm" @click="openAddDrawer">
        <Plus class="w-3.5 h-3.5" />
        Add Route
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
      v-else-if="routes.length === 0 && !loadError"
      size="md"
      title="No routes yet"
      message="Add your first route to start scheduling trips."
    >
      <template #icon="{ iconClass }">
        <RouteIcon :class="iconClass" />
      </template>
      <template #action>
        <BaseButton variant="primary" size="sm" @click="openAddDrawer">Add Route</BaseButton>
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
              Distance
            </th>
            <th class="font-display uppercase tracking-wider text-[11px] text-muted px-4 py-3">
              Duration
            </th>
            <th class="px-4 py-3" />
          </tr>
        </thead>
        <tbody>
          <template v-for="route in routes" :key="route.id">
            <tr class="border-b border-border last:border-b-0">
              <td class="px-4 py-3">
                {{ route.origin_terminal }} <span class="text-muted mx-1">→</span>
                {{ route.destination_terminal }}
              </td>
              <td class="px-4 py-3 font-mono text-xs">{{ route.distance_km }} km</td>
              <td class="px-4 py-3 font-mono text-xs">
                {{ formatMinutes(route.estimated_duration_minutes) }}
              </td>
              <td class="px-4 py-3 text-right">
                <span v-if="confirmingId !== route.id" class="inline-flex gap-2">
                  <BaseButton
                    variant="secondary"
                    size="sm"
                    icon-only
                    aria-label="Edit route"
                    @click="openEditDrawer(route)"
                  >
                    <Pencil class="w-4 h-4" />
                  </BaseButton>
                  <BaseButton
                    variant="secondary"
                    size="sm"
                    icon-only
                    aria-label="Delete route"
                    @click="confirmingId = route.id"
                  >
                    <Trash2 class="w-4 h-4" />
                  </BaseButton>
                </span>
              </td>
            </tr>
            <tr v-if="confirmingId === route.id" class="bg-danger/5 border-b border-border">
              <td colspan="4" class="px-3 py-3">
                <BaseDialog
                  layout="inline"
                  variant="danger"
                  :message="`Delete ${route.origin_terminal} → ${route.destination_terminal}? This can't be undone.`"
                  confirm-label="Yes, Delete"
                  cancel-label="Keep"
                  :loading="deletingId === route.id"
                  @confirm="onDelete(route)"
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
      :title="editingId ? 'Edit Route' : 'Add Route'"
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

        <BaseAutocomplete
          id="route-origin"
          v-model="originId"
          v-model:query="originQuery"
          :loader="loadTerminals"
          :disabled="submitting"
          :error="originError"
          label="Origin terminal"
          placeholder="Select terminal…"
        >
          <template #leading="{ iconClass }">
            <MapPin :class="iconClass" class="w-4 h-4 shrink-0" />
          </template>
        </BaseAutocomplete>

        <BaseAutocomplete
          id="route-destination"
          v-model="destinationId"
          v-model:query="destinationQuery"
          :loader="loadTerminals"
          :disabled="submitting"
          :error="destinationError"
          label="Destination terminal"
          placeholder="Select terminal…"
        >
          <template #leading="{ iconClass }">
            <MapPin :class="iconClass" class="w-4 h-4 shrink-0" />
          </template>
        </BaseAutocomplete>

        <div class="grid grid-cols-2 gap-3">
          <BaseInput
            id="route-distance"
            v-model="distanceKm"
            label="Distance (km)"
            placeholder="e.g. 246"
            :disabled="submitting"
            :error="distanceError"
          />
          <BaseInput
            id="route-duration"
            v-model="durationMinutes"
            label="Est. duration (minutes)"
            placeholder="e.g. 390"
            :disabled="submitting"
            :error="durationError"
          />
        </div>

        <div class="flex gap-3 pt-2">
          <BaseButton
            type="submit"
            variant="primary"
            class="flex-1"
            :loading="submitting"
            loading-text="Saving…"
          >
            Save Route
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
