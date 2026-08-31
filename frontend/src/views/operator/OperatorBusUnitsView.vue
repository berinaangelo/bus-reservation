<script setup lang="ts">
// Bus Units CRUD — same list+drawer shape as OperatorRoutesView.vue (local refs, no store; there's
// no CRUD-store precedent anywhere in this codebase). The odd one out among the four operator
// resources: bus_class is Rails STI (BusUnit -> OrdinaryBusUnit / ReservableBusUnit ->
// Aircon/Deluxe/DoubleDeckBusUnit), switched on update via `becomes!`. OrdinaryBusUnit requires
// seat_layout absent; every reservable subclass requires it present — so this form both switches
// class and captures/clears seat_layout (rows/columns dimensions only; the per-seat grid is a
// separate future flow, not this form's job). Switching an existing unit from a reservable class
// to Ordinary wipes its seat layout, so that transition is gated by an inline confirm step before
// the request is sent (user decision) rather than a silent submit or a bare 422.
import { computed, onMounted, ref } from 'vue'
import { Bus, Check, Pencil, Plus, Trash2 } from '@lucide/vue'
import { listBusUnits, createBusUnit, updateBusUnit, deleteBusUnit } from '../../api/operator/busUnits'
import type { OperatorBusUnitParams } from '../../api/operator/busUnits'
import type { OperatorBusUnit } from '../../types/operator'
import type { BusClass } from '../../types/trip'
import { ApiError } from '../../api/types'
import type { SelectOption } from '../../types/ui'
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

const busClassOptions: SelectOption<BusClass>[] = (
  Object.keys(BUS_CLASS_LABELS) as BusClass[]
).map((value) => ({ label: BUS_CLASS_LABELS[value], value }))

interface SeatDims {
  rows: number
  columns: number
}

function dimsOf(value: unknown): Partial<SeatDims> {
  return value && typeof value === 'object' ? (value as Partial<SeatDims>) : {}
}

const busUnits = ref<OperatorBusUnit[]>([])
const loading = ref(true)
const loadError = ref<string | null>(null)
const successMessage = ref<string | null>(null)

const drawerOpen = ref(false)
const editingId = ref<number | null>(null)

const plateNumber = ref('')
const plateError = ref<string | undefined>(undefined)

const busClass = ref<BusClass | null>(null)
const busClassError = ref<string | undefined>(undefined)
const originalBusClass = ref<BusClass | null>(null)

const totalSeats = ref('')
const totalSeatsError = ref<string | undefined>(undefined)

const active = ref(true)

const rows = ref('')
const rowsError = ref<string | undefined>(undefined)
const columns = ref('')
const columnsError = ref<string | undefined>(undefined)

const lowerRows = ref('')
const lowerRowsError = ref<string | undefined>(undefined)
const lowerColumns = ref('')
const lowerColumnsError = ref<string | undefined>(undefined)
const upperRows = ref('')
const upperRowsError = ref<string | undefined>(undefined)
const upperColumns = ref('')
const upperColumnsError = ref<string | undefined>(undefined)

const showSwitchConfirm = ref(false)
const formError = ref<string | null>(null)
const submitting = ref(false)

const confirmingId = ref<number | null>(null)
const deletingId = ref<number | null>(null)

const isReservable = computed(() => busClass.value !== null && busClass.value !== 'ordinary')
const isDoubleDeck = computed(() => busClass.value === 'double_deck')

async function load() {
  loading.value = true
  loadError.value = null
  try {
    const res = await listBusUnits()
    busUnits.value = res.bus_units
  } catch (e) {
    loadError.value = e instanceof ApiError ? e.message : 'Could not load bus units. Try again.'
  } finally {
    loading.value = false
  }
}

onMounted(load)

function resetForm() {
  plateNumber.value = ''
  plateError.value = undefined
  busClass.value = null
  busClassError.value = undefined
  originalBusClass.value = null
  totalSeats.value = ''
  totalSeatsError.value = undefined
  active.value = true
  rows.value = ''
  rowsError.value = undefined
  columns.value = ''
  columnsError.value = undefined
  lowerRows.value = ''
  lowerRowsError.value = undefined
  lowerColumns.value = ''
  lowerColumnsError.value = undefined
  upperRows.value = ''
  upperRowsError.value = undefined
  upperColumns.value = ''
  upperColumnsError.value = undefined
  showSwitchConfirm.value = false
  formError.value = null
}

function openAddDrawer() {
  editingId.value = null
  resetForm()
  drawerOpen.value = true
}

function openEditDrawer(unit: OperatorBusUnit) {
  editingId.value = unit.id
  resetForm()
  plateNumber.value = unit.plate_number
  busClass.value = unit.bus_class
  originalBusClass.value = unit.bus_class
  totalSeats.value = String(unit.total_seats)
  active.value = unit.active

  if (unit.bus_class === 'double_deck') {
    const lower = dimsOf(unit.seat_layout.lower)
    const upper = dimsOf(unit.seat_layout.upper)
    lowerRows.value = lower.rows != null ? String(lower.rows) : ''
    lowerColumns.value = lower.columns != null ? String(lower.columns) : ''
    upperRows.value = upper.rows != null ? String(upper.rows) : ''
    upperColumns.value = upper.columns != null ? String(upper.columns) : ''
  } else if (unit.bus_class !== 'ordinary') {
    const dims = dimsOf(unit.seat_layout)
    rows.value = dims.rows != null ? String(dims.rows) : ''
    columns.value = dims.columns != null ? String(dims.columns) : ''
  }

  drawerOpen.value = true
}

function positiveIntegerError(value: string): string | undefined {
  const n = Number(value)
  return value.trim() && Number.isInteger(n) && n > 0 ? undefined : 'Must be a whole number greater than 0.'
}

function validate(): boolean {
  plateError.value = plateNumber.value.trim() ? undefined : 'Enter a plate number.'
  busClassError.value = busClass.value ? undefined : 'Select a class.'
  totalSeatsError.value = positiveIntegerError(totalSeats.value)

  rowsError.value = undefined
  columnsError.value = undefined
  lowerRowsError.value = undefined
  lowerColumnsError.value = undefined
  upperRowsError.value = undefined
  upperColumnsError.value = undefined

  if (isDoubleDeck.value) {
    lowerRowsError.value = positiveIntegerError(lowerRows.value)
    lowerColumnsError.value = positiveIntegerError(lowerColumns.value)
    upperRowsError.value = positiveIntegerError(upperRows.value)
    upperColumnsError.value = positiveIntegerError(upperColumns.value)
  } else if (isReservable.value) {
    rowsError.value = positiveIntegerError(rows.value)
    columnsError.value = positiveIntegerError(columns.value)
  }

  return !(
    plateError.value ||
    busClassError.value ||
    totalSeatsError.value ||
    rowsError.value ||
    columnsError.value ||
    lowerRowsError.value ||
    lowerColumnsError.value ||
    upperRowsError.value ||
    upperColumnsError.value
  )
}

function buildSeatLayout(): Record<string, unknown> {
  if (busClass.value === 'double_deck') {
    return {
      lower: { rows: Number(lowerRows.value), columns: Number(lowerColumns.value) },
      upper: { rows: Number(upperRows.value), columns: Number(upperColumns.value) },
    }
  }
  if (isReservable.value) {
    return { rows: Number(rows.value), columns: Number(columns.value) }
  }
  // Explicit, not omitted: this is what clears a prior reservable unit's layout on PATCH — omitting
  // the key would leave the old value in place (assign_attributes only touches keys actually sent),
  // and OrdinaryBusUnit's `validates :seat_layout, absence: true` would then reject the save.
  return {}
}

async function performSubmit() {
  const params: OperatorBusUnitParams = {
    bus_class: busClass.value!,
    plate_number: plateNumber.value,
    total_seats: Number(totalSeats.value),
    active: active.value,
    seat_layout: buildSeatLayout(),
  }

  submitting.value = true
  try {
    if (editingId.value) {
      await updateBusUnit(editingId.value, params)
      successMessage.value = `Updated ${plateNumber.value}.`
    } else {
      await createBusUnit(params)
      successMessage.value = `Added ${plateNumber.value}.`
    }
    drawerOpen.value = false
    await load()
  } catch (e) {
    if (e instanceof ApiError && e.fieldErrors) {
      plateError.value = e.fieldErrors.plate_number?.[0]
      totalSeatsError.value = e.fieldErrors.total_seats?.[0]
      if (!plateError.value && !totalSeatsError.value) {
        formError.value = e.message
      }
    } else {
      formError.value = e instanceof ApiError ? e.message : 'Something went wrong. Try again.'
    }
  } finally {
    submitting.value = false
    showSwitchConfirm.value = false
  }
}

async function onSubmit() {
  formError.value = null
  if (!validate()) return

  const switchingToOrdinaryFromReservable =
    editingId.value !== null &&
    originalBusClass.value !== null &&
    originalBusClass.value !== 'ordinary' &&
    busClass.value === 'ordinary'

  if (switchingToOrdinaryFromReservable && !showSwitchConfirm.value) {
    showSwitchConfirm.value = true
    return
  }

  await performSubmit()
}

async function onDelete(unit: OperatorBusUnit) {
  deletingId.value = unit.id
  try {
    await deleteBusUnit(unit.id)
    confirmingId.value = null
    await load()
  } catch (e) {
    loadError.value = e instanceof ApiError ? e.message : 'Could not delete bus unit. Try again.'
  } finally {
    deletingId.value = null
  }
}
</script>

<template>
  <div>
    <div class="flex items-center justify-between mb-5">
      <h1 class="font-display text-2xl font-bold">Bus Units</h1>
      <BaseButton variant="primary" size="sm" @click="openAddDrawer">
        <Plus class="w-3.5 h-3.5" />
        Add Bus Unit
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
      v-else-if="busUnits.length === 0 && !loadError"
      size="md"
      title="No bus units yet"
      message="Add a bus unit before scheduling trips — every trip needs one assigned."
    >
      <template #icon="{ iconClass }">
        <Bus :class="iconClass" />
      </template>
      <template #action>
        <BaseButton variant="primary" size="sm" @click="openAddDrawer">Add Bus Unit</BaseButton>
      </template>
    </Empty>

    <div v-else class="border border-border bg-surface overflow-x-auto">
      <table class="w-full text-sm">
        <thead>
          <tr class="border-b border-border text-left">
            <th class="font-display uppercase tracking-wider text-[11px] text-muted px-4 py-3">
              Plate Number
            </th>
            <th class="font-display uppercase tracking-wider text-[11px] text-muted px-4 py-3">
              Class
            </th>
            <th class="font-display uppercase tracking-wider text-[11px] text-muted px-4 py-3">
              Total Seats
            </th>
            <th class="font-display uppercase tracking-wider text-[11px] text-muted px-4 py-3">
              Status
            </th>
            <th class="px-4 py-3" />
          </tr>
        </thead>
        <tbody>
          <template v-for="unit in busUnits" :key="unit.id">
            <tr class="border-b border-border last:border-b-0">
              <td class="px-4 py-3 font-mono text-xs">{{ unit.plate_number }}</td>
              <td class="px-4 py-3">
                <span
                  class="px-2 py-0.5 text-[11px] font-medium border"
                  :class="
                    unit.bus_class === 'double_deck'
                      ? 'border-secondary text-secondary bg-secondary/10'
                      : 'border-border text-text bg-surface'
                  "
                >
                  {{ BUS_CLASS_LABELS[unit.bus_class] }}
                </span>
              </td>
              <td class="px-4 py-3 font-mono text-xs">{{ unit.total_seats }}</td>
              <td class="px-4 py-3">{{ unit.active ? 'Active' : 'Inactive' }}</td>
              <td class="px-4 py-3 text-right">
                <span v-if="confirmingId !== unit.id" class="inline-flex gap-2">
                  <BaseButton
                    variant="secondary"
                    size="sm"
                    icon-only
                    aria-label="Edit bus unit"
                    @click="openEditDrawer(unit)"
                  >
                    <Pencil class="w-4 h-4" />
                  </BaseButton>
                  <BaseButton
                    variant="secondary"
                    size="sm"
                    icon-only
                    aria-label="Delete bus unit"
                    @click="confirmingId = unit.id"
                  >
                    <Trash2 class="w-4 h-4" />
                  </BaseButton>
                </span>
              </td>
            </tr>
            <tr v-if="confirmingId === unit.id" class="bg-danger/5 border-b border-border">
              <td colspan="5" class="px-3 py-3">
                <BaseDialog
                  layout="inline"
                  variant="danger"
                  :message="`Delete bus unit ${unit.plate_number}? This can't be undone.`"
                  confirm-label="Yes, Delete"
                  cancel-label="Keep"
                  :loading="deletingId === unit.id"
                  @confirm="onDelete(unit)"
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
      :title="editingId ? 'Edit Bus Unit' : 'Add Bus Unit'"
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

        <BaseInput
          id="bus-unit-plate"
          v-model="plateNumber"
          label="Plate number"
          placeholder="e.g. NHW 1234"
          :disabled="submitting"
          :error="plateError"
        />

        <BaseSelect
          id="bus-unit-class"
          v-model="busClass"
          :options="busClassOptions"
          :disabled="submitting"
          :error="busClassError"
          label="Bus class"
          placeholder="Select class…"
        />

        <BaseInput
          id="bus-unit-total-seats"
          v-model="totalSeats"
          label="Total seats"
          placeholder="e.g. 45"
          :disabled="submitting"
          :error="totalSeatsError"
        />

        <div v-if="isDoubleDeck" class="space-y-4">
          <div>
            <p class="font-display uppercase tracking-wider text-[11px] text-muted mb-1.5">
              Lower deck
            </p>
            <div class="grid grid-cols-2 gap-3">
              <BaseInput
                id="bus-unit-lower-rows"
                v-model="lowerRows"
                label="Rows"
                placeholder="e.g. 9"
                :disabled="submitting"
                :error="lowerRowsError"
              />
              <BaseInput
                id="bus-unit-lower-columns"
                v-model="lowerColumns"
                label="Columns"
                placeholder="e.g. 4"
                :disabled="submitting"
                :error="lowerColumnsError"
              />
            </div>
          </div>
          <div>
            <p class="font-display uppercase tracking-wider text-[11px] text-muted mb-1.5">
              Upper deck
            </p>
            <div class="grid grid-cols-2 gap-3">
              <BaseInput
                id="bus-unit-upper-rows"
                v-model="upperRows"
                label="Rows"
                placeholder="e.g. 9"
                :disabled="submitting"
                :error="upperRowsError"
              />
              <BaseInput
                id="bus-unit-upper-columns"
                v-model="upperColumns"
                label="Columns"
                placeholder="e.g. 4"
                :disabled="submitting"
                :error="upperColumnsError"
              />
            </div>
          </div>
        </div>
        <div v-else-if="isReservable" class="grid grid-cols-2 gap-3">
          <BaseInput
            id="bus-unit-rows"
            v-model="rows"
            label="Rows"
            placeholder="e.g. 12"
            :disabled="submitting"
            :error="rowsError"
          />
          <BaseInput
            id="bus-unit-columns"
            v-model="columns"
            label="Columns"
            placeholder="e.g. 4"
            :disabled="submitting"
            :error="columnsError"
          />
        </div>

        <label for="bus-unit-active" class="flex items-center gap-2 cursor-pointer w-fit">
          <input id="bus-unit-active" v-model="active" type="checkbox" class="sr-only peer" />
          <span
            class="w-4 h-4 border-2 border-primary flex items-center justify-center shrink-0 peer-checked:bg-primary"
          >
            <Check class="w-3 h-3 text-white hidden peer-checked:block" />
          </span>
          <span class="text-sm text-text">Active (available to assign to trips)</span>
        </label>

        <BaseDialog
          v-if="showSwitchConfirm"
          layout="stacked"
          variant="danger"
          message="Switching to Ordinary clears this bus's seat layout. This can't be undone."
          confirm-label="Yes, Switch & Save"
          cancel-label="Keep Reservable"
          :loading="submitting"
          @confirm="performSubmit"
          @cancel="showSwitchConfirm = false"
        />
        <div v-else class="flex gap-3 pt-2">
          <BaseButton
            type="submit"
            variant="primary"
            class="flex-1"
            :loading="submitting"
            loading-text="Saving…"
          >
            Save Bus Unit
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
