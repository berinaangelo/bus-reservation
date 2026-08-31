<script setup lang="ts">
// Dev-only living catalog of the base UI kit (frontend/src/components/ui/). Stripped from
// production builds — see the import.meta.env.DEV guard in router/index.ts.
import { ref } from 'vue'
import { MapPin, Search, Plus, Bus } from '@lucide/vue'
import BaseButton from '../../components/ui/BaseButton.vue'
import BaseInput from '../../components/ui/BaseInput.vue'
import PasswordInput from '../../components/ui/PasswordInput.vue'
import BaseSelect from '../../components/ui/BaseSelect.vue'
import BaseAutocomplete from '../../components/ui/BaseAutocomplete.vue'
import BaseDialog from '../../components/ui/BaseDialog.vue'
import BaseDrawer from '../../components/ui/BaseDrawer.vue'
import BaseToast from '../../components/ui/BaseToast.vue'
import Empty from '../../components/ui/Empty.vue'
import type { SelectOption } from '../../types/ui'

const textValue = ref('')
const errorValue = ref('Cubao')
const passwordValue = ref('')

const terminalOptions: SelectOption<number>[] = [
  { label: 'Cubao, Quezon City', value: 1 },
  { label: 'Baguio City', value: 2 },
  { label: 'Dagupan City', value: 3 },
]
const selectValue = ref<number | null>(null)
const selectErrorValue = ref<number | null>(null)

const autocompleteValue = ref<number | null>(null)
const autocompleteQuery = ref('')
async function mockTerminalLoader(q: string): Promise<SelectOption<number>[]> {
  await new Promise((resolve) => setTimeout(resolve, 400)) // simulate network latency
  return terminalOptions.filter((opt) => opt.label.toLowerCase().includes(q.toLowerCase()))
}

const showStackedDialog = ref(true)
const showInlineDialog = ref(true)
const dialogLoading = ref(false)

const drawerOpen = ref(false)

const dismissibleToasts = ref({ danger: true, success: true, warning: true, info: true })
</script>

<template>
  <div class="min-h-screen bg-background p-8 space-y-12 max-w-3xl mx-auto">
    <h1 class="font-display text-3xl font-bold text-primary">UI Kit Preview</h1>

    <!-- BaseButton -->
    <section class="space-y-3">
      <h2
        class="font-display uppercase tracking-wide text-sm text-muted border-b border-border pb-1"
      >
        BaseButton
      </h2>
      <div class="flex flex-wrap items-center gap-3">
        <BaseButton variant="primary">Search trips</BaseButton>
        <BaseButton variant="secondary">Clear search</BaseButton>
        <BaseButton variant="danger">Cancel Booking</BaseButton>
        <BaseButton variant="danger-filled">Yes, Delete</BaseButton>
      </div>
      <div class="flex flex-wrap items-center gap-3">
        <BaseButton variant="primary" size="sm">Save Route</BaseButton>
        <BaseButton variant="secondary" size="sm">Keep</BaseButton>
        <BaseButton variant="primary" disabled>Disabled</BaseButton>
        <BaseButton variant="primary" loading loading-text="Searching…">Search trips</BaseButton>
        <BaseButton variant="danger-filled" loading>Yes, Delete</BaseButton>
        <BaseButton icon-only aria-label="Swap">
          <Search class="w-5 h-5" />
        </BaseButton>
      </div>
    </section>

    <!-- BaseInput / PasswordInput -->
    <section class="space-y-3">
      <h2
        class="font-display uppercase tracking-wide text-sm text-muted border-b border-border pb-1"
      >
        BaseInput / PasswordInput
      </h2>
      <BaseInput v-model="textValue" label="Contact number" placeholder="09XX XXX XXXX">
        <template #leading="{ iconClass }">
          <MapPin :class="iconClass" class="w-4 h-4 shrink-0" />
        </template>
      </BaseInput>
      <BaseInput v-model="errorValue" label="Origin terminal" error="Destination is required." />
      <BaseInput model-value="Locked" label="Disabled field" disabled />
      <PasswordInput
        v-model="passwordValue"
        label="Password"
        placeholder="••••••••"
        autocomplete="current-password"
      />
    </section>

    <!-- BaseSelect -->
    <section class="space-y-3">
      <h2
        class="font-display uppercase tracking-wide text-sm text-muted border-b border-border pb-1"
      >
        BaseSelect
      </h2>
      <BaseSelect v-model="selectValue" :options="terminalOptions" label="Destination terminal">
        <template #icon="{ iconClass }">
          <MapPin :class="iconClass" class="w-4 h-4 shrink-0" />
        </template>
      </BaseSelect>
      <BaseSelect
        v-model="selectErrorValue"
        :options="terminalOptions"
        label="Destination terminal"
        error="Destination is required."
      />
    </section>

    <!-- BaseAutocomplete -->
    <section class="space-y-3">
      <h2
        class="font-display uppercase tracking-wide text-sm text-muted border-b border-border pb-1"
      >
        BaseAutocomplete
      </h2>
      <BaseAutocomplete
        v-model="autocompleteValue"
        v-model:query="autocompleteQuery"
        :loader="mockTerminalLoader"
        label="From"
        placeholder="Origin terminal"
      >
        <template #leading="{ iconClass }">
          <MapPin :class="iconClass" class="w-4 h-4 shrink-0" />
        </template>
      </BaseAutocomplete>
    </section>

    <!-- BaseDialog -->
    <section class="space-y-3">
      <h2
        class="font-display uppercase tracking-wide text-sm text-muted border-b border-border pb-1"
      >
        BaseDialog
      </h2>
      <BaseDialog
        v-if="showStackedDialog"
        message="Cancel this booking? This can't be undone."
        confirm-label="Yes, Cancel"
        cancel-label="Keep Booking"
        :loading="dialogLoading"
        @cancel="showStackedDialog = false"
        @confirm="showStackedDialog = false"
      />
      <table v-if="showInlineDialog" class="w-full border border-border">
        <tbody>
          <tr>
            <td colspan="2" class="p-0">
              <BaseDialog
                layout="inline"
                message="Delete Cubao → Baguio? This can't be undone."
                confirm-label="Yes, Delete"
                cancel-label="Keep"
                @cancel="showInlineDialog = false"
                @confirm="showInlineDialog = false"
              />
            </td>
          </tr>
        </tbody>
      </table>
    </section>

    <!-- BaseDrawer -->
    <section class="space-y-3">
      <h2
        class="font-display uppercase tracking-wide text-sm text-muted border-b border-border pb-1"
      >
        BaseDrawer
      </h2>
      <BaseButton variant="primary" @click="drawerOpen = true">Add Route</BaseButton>
      <BaseDrawer v-model="drawerOpen" title="Add Route">
        <form class="space-y-4" @submit.prevent="drawerOpen = false">
          <BaseInput model-value="" label="Route name" placeholder="Cubao → Baguio" />
          <div class="flex gap-3 pt-2">
            <BaseButton type="submit" variant="primary" class="flex-1">Save Route</BaseButton>
            <BaseButton type="button" variant="secondary" class="flex-1" @click="drawerOpen = false"
              >Cancel</BaseButton
            >
          </div>
        </form>
      </BaseDrawer>
    </section>

    <!-- BaseToast -->
    <section class="space-y-3">
      <h2
        class="font-display uppercase tracking-wide text-sm text-muted border-b border-border pb-1"
      >
        BaseToast
      </h2>
      <BaseToast
        v-if="dismissibleToasts.danger"
        variant="danger"
        title="Couldn't save"
        message="Email or password is wrong."
        @dismiss="dismissibleToasts.danger = false"
      />
      <BaseToast
        v-if="dismissibleToasts.success"
        variant="success"
        message="Route saved."
        @dismiss="dismissibleToasts.success = false"
      />
      <BaseToast
        v-if="dismissibleToasts.warning"
        variant="warning"
        message="This trip's departure is in the past."
        @dismiss="dismissibleToasts.warning = false"
      />
      <BaseToast
        v-if="dismissibleToasts.info"
        variant="info"
        message="Bus Unit options are scoped to this departure window."
        @dismiss="dismissibleToasts.info = false"
      />
    </section>

    <!-- Empty -->
    <section class="space-y-3">
      <h2
        class="font-display uppercase tracking-wide text-sm text-muted border-b border-border pb-1"
      >
        Empty
      </h2>
      <Empty
        title="No trips found"
        message="Cubao, Quezon City → Baguio City · Aug 28, 2026 has no available trips. Try a different date or route."
      >
        <template #icon="{ iconClass }">
          <Search :class="iconClass" />
        </template>
        <template #action>
          <BaseButton variant="secondary">Clear search</BaseButton>
        </template>
      </Empty>
      <Empty
        size="md"
        title="No routes yet"
        message="Add your first route to start scheduling trips for Sierra Madre Trans."
      >
        <template #icon="{ iconClass }">
          <Bus :class="iconClass" />
        </template>
        <template #action>
          <BaseButton variant="primary" size="sm">
            <Plus class="w-3.5 h-3.5" />
            Add Route
          </BaseButton>
        </template>
      </Empty>
    </section>
  </div>
</template>
