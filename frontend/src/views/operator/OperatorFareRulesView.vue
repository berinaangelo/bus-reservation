<script setup lang="ts">
// Fare Rules CRUD — same list+drawer shape as OperatorRoutesView.vue/OperatorBusUnitsView.vue
// (local refs, no store). Two things set this resource apart: route_id is immutable after create
// (see updateFareRule's Partial<Omit<..., 'route_id'>> type and the controller's
// fare_rule_params.except(:route_id)), so the edit drawer shows Route read-only; and base_fare is
// stored in centavos but entered/displayed in pesos, so this form does the peso<->centavo
// conversion at its boundary. Per the mockup, editing an already-effective fare rule is the
// "unusual path" — a warning banner replaces the usual helper text in that case, since fare rules
// are meant to be superseded by a new future-dated row rather than rewritten.
import { computed, onMounted, ref } from 'vue'
import { Banknote, Pencil, Plus, Trash2 } from '@lucide/vue'
import {
  listFareRules,
  createFareRule,
  updateFareRule,
  deleteFareRule,
} from '../../api/operator/fareRules'
import type { OperatorFareRuleParams } from '../../api/operator/fareRules'
import { listRoutes } from '../../api/operator/routes'
import type { OperatorFareRule, OperatorRoute } from '../../types/operator'
import type { BusClass } from '../../types/trip'
import { ApiError } from '../../api/types'
import type { SelectOption } from '../../types/ui'
import { todayLocalISODate } from '../../utils/tripSearchForm'
import { formatFare, formatDate } from '../../utils/format'
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

function parseBaseFareToCentavos(value: string): number | null {
  const pesos = Number(value)
  return value.trim() && Number.isFinite(pesos) && pesos > 0 ? Math.round(pesos * 100) : null
}

function routeLabel(route: OperatorRoute): string {
  return `${route.origin_terminal} → ${route.destination_terminal}`
}

const fareRules = ref<OperatorFareRule[]>([])
const routes = ref<OperatorRoute[]>([])
const loading = ref(true)
const loadError = ref<string | null>(null)
const successMessage = ref<string | null>(null)

const routeOptions = computed<SelectOption<number>[]>(() =>
  routes.value.map((r) => ({ label: routeLabel(r), value: r.id })),
)
const routesById = computed(() => new Map(routes.value.map((r) => [r.id, r])))

const drawerOpen = ref(false)
const editingId = ref<number | null>(null)

const routeId = ref<number | null>(null)
const routeError = ref<string | undefined>(undefined)

const busClass = ref<BusClass | null>(null)
const busClassError = ref<string | undefined>(undefined)

const baseFarePesos = ref('')
const baseFareError = ref<string | undefined>(undefined)

const effectiveDate = ref('')
const effectiveDateError = ref<string | undefined>(undefined)

const formError = ref<string | null>(null)
const submitting = ref(false)

const confirmingId = ref<number | null>(null)
const deletingId = ref<number | null>(null)

const isAlreadyEffective = computed(
  () => editingId.value !== null && effectiveDate.value !== '' && effectiveDate.value <= todayLocalISODate(),
)

async function load() {
  loading.value = true
  loadError.value = null
  try {
    const [fareRulesRes, routesRes] = await Promise.all([listFareRules(), listRoutes()])
    fareRules.value = fareRulesRes.fare_rules
    routes.value = routesRes.routes
  } catch (e) {
    loadError.value = e instanceof ApiError ? e.message : 'Could not load fare rules. Try again.'
  } finally {
    loading.value = false
  }
}

onMounted(load)

function resetForm() {
  routeId.value = null
  routeError.value = undefined
  busClass.value = null
  busClassError.value = undefined
  baseFarePesos.value = ''
  baseFareError.value = undefined
  effectiveDate.value = ''
  effectiveDateError.value = undefined
  formError.value = null
}

function openAddDrawer() {
  editingId.value = null
  resetForm()
  drawerOpen.value = true
}

function openEditDrawer(rule: OperatorFareRule) {
  editingId.value = rule.id
  resetForm()
  routeId.value = rule.route_id
  busClass.value = rule.bus_class
  baseFarePesos.value = (rule.base_fare / 100).toFixed(2)
  effectiveDate.value = rule.effective_date
  drawerOpen.value = true
}

function validate(): boolean {
  routeError.value = routeId.value ? undefined : 'Select a route.'
  busClassError.value = busClass.value ? undefined : 'Select a class.'
  baseFareError.value =
    parseBaseFareToCentavos(baseFarePesos.value) !== null
      ? undefined
      : 'Enter a fare greater than 0.'
  effectiveDateError.value = effectiveDate.value ? undefined : 'Select an effective date.'

  return (
    !routeError.value && !busClassError.value && !baseFareError.value && !effectiveDateError.value
  )
}

async function onSubmit() {
  formError.value = null
  if (!validate()) return

  submitting.value = true
  try {
    if (editingId.value) {
      const params: Partial<Omit<OperatorFareRuleParams, 'route_id'>> = {
        bus_class: busClass.value!,
        base_fare: parseBaseFareToCentavos(baseFarePesos.value)!,
        effective_date: effectiveDate.value,
      }
      await updateFareRule(editingId.value, params)
      successMessage.value = `Updated fare rule for ${BUS_CLASS_LABELS[busClass.value!]}.`
    } else {
      const params: OperatorFareRuleParams = {
        route_id: routeId.value!,
        bus_class: busClass.value!,
        base_fare: parseBaseFareToCentavos(baseFarePesos.value)!,
        effective_date: effectiveDate.value,
      }
      await createFareRule(params)
      successMessage.value = `Added fare rule for ${BUS_CLASS_LABELS[busClass.value!]}.`
    }
    drawerOpen.value = false
    await load()
  } catch (e) {
    if (e instanceof ApiError && e.fieldErrors) {
      busClassError.value = e.fieldErrors.bus_class?.[0]
      baseFareError.value = e.fieldErrors.base_fare?.[0]
      effectiveDateError.value = e.fieldErrors.effective_date?.[0]
      if (!busClassError.value && !baseFareError.value && !effectiveDateError.value) {
        formError.value = e.message
      }
    } else {
      formError.value = e instanceof ApiError ? e.message : 'Something went wrong. Try again.'
    }
  } finally {
    submitting.value = false
  }
}

async function onDelete(rule: OperatorFareRule) {
  deletingId.value = rule.id
  try {
    await deleteFareRule(rule.id)
    confirmingId.value = null
    await load()
  } catch (e) {
    loadError.value = e instanceof ApiError ? e.message : 'Could not delete fare rule. Try again.'
  } finally {
    deletingId.value = null
  }
}
</script>

<template>
  <div>
    <div class="flex items-center justify-between mb-5">
      <h1 class="font-display text-2xl font-bold">Fare Rules</h1>
      <BaseButton variant="primary" size="sm" @click="openAddDrawer">
        <Plus class="w-3.5 h-3.5" />
        Add Fare Rule
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
      v-else-if="fareRules.length === 0 && !loadError"
      size="md"
      title="No fare rules yet"
      message="Add a fare rule for each route/class combination you plan to run."
    >
      <template #icon="{ iconClass }">
        <Banknote :class="iconClass" />
      </template>
      <template #action>
        <BaseButton variant="primary" size="sm" @click="openAddDrawer">Add Fare Rule</BaseButton>
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
              Class
            </th>
            <th class="font-display uppercase tracking-wider text-[11px] text-muted px-4 py-3">
              Base Fare
            </th>
            <th class="font-display uppercase tracking-wider text-[11px] text-muted px-4 py-3">
              Effective
            </th>
            <th class="px-4 py-3" />
          </tr>
        </thead>
        <tbody>
          <template v-for="rule in fareRules" :key="rule.id">
            <tr class="border-b border-border last:border-b-0">
              <td class="px-4 py-3">
                <template v-if="routesById.get(rule.route_id)">
                  {{ routesById.get(rule.route_id)!.origin_terminal }}
                  <span class="text-muted mx-1">→</span>
                  {{ routesById.get(rule.route_id)!.destination_terminal }}
                </template>
                <span v-else class="text-muted">Unknown route</span>
              </td>
              <td class="px-4 py-3">{{ BUS_CLASS_LABELS[rule.bus_class] }}</td>
              <td class="px-4 py-3 font-mono text-xs">{{ formatFare(rule.base_fare) }}</td>
              <td class="px-4 py-3 font-mono text-xs">{{ formatDate(rule.effective_date) }}</td>
              <td class="px-4 py-3 text-right">
                <span v-if="confirmingId !== rule.id" class="inline-flex gap-2">
                  <BaseButton
                    variant="secondary"
                    size="sm"
                    icon-only
                    aria-label="Edit fare rule"
                    @click="openEditDrawer(rule)"
                  >
                    <Pencil class="w-4 h-4" />
                  </BaseButton>
                  <BaseButton
                    variant="secondary"
                    size="sm"
                    icon-only
                    aria-label="Delete fare rule"
                    @click="confirmingId = rule.id"
                  >
                    <Trash2 class="w-4 h-4" />
                  </BaseButton>
                </span>
              </td>
            </tr>
            <tr v-if="confirmingId === rule.id" class="bg-danger/5 border-b border-border">
              <td colspan="5" class="px-3 py-3">
                <BaseDialog
                  layout="inline"
                  variant="danger"
                  :message="`Delete this fare rule (${formatFare(rule.base_fare)}, ${BUS_CLASS_LABELS[rule.bus_class]})? This can't be undone.`"
                  confirm-label="Yes, Delete"
                  cancel-label="Keep"
                  :loading="deletingId === rule.id"
                  @confirm="onDelete(rule)"
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
      :title="editingId ? 'Edit Fare Rule' : 'Add Fare Rule'"
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
        <BaseToast
          v-if="isAlreadyEffective"
          variant="warning"
          message="This fare is already effective. Consider Add Fare Rule with a future date instead of editing history."
          :dismissible="false"
          class="mb-1"
        />

        <div>
          <BaseSelect
            id="fare-rule-route"
            v-model="routeId"
            :options="routeOptions"
            :disabled="submitting || editingId !== null"
            :error="routeError"
            label="Route"
            placeholder="Select route…"
          />
          <p v-if="editingId !== null" class="text-[11px] text-muted mt-1">
            Route can't be changed after creation.
          </p>
        </div>

        <BaseSelect
          id="fare-rule-class"
          v-model="busClass"
          :options="busClassOptions"
          :disabled="submitting"
          :error="busClassError"
          label="Bus class"
          placeholder="Select class…"
        />

        <BaseInput
          id="fare-rule-base-fare"
          v-model="baseFarePesos"
          label="Base fare (₱)"
          placeholder="0.00"
          :disabled="submitting"
          :error="baseFareError"
        />

        <BaseInput
          id="fare-rule-effective-date"
          v-model="effectiveDate"
          type="date"
          label="Effective date"
          :min="editingId === null ? todayLocalISODate() : undefined"
          :disabled="submitting"
          :error="effectiveDateError"
        />

        <div class="flex gap-3 pt-2">
          <BaseButton
            type="submit"
            variant="primary"
            class="flex-1"
            :loading="submitting"
            loading-text="Saving…"
          >
            Save Fare Rule
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
