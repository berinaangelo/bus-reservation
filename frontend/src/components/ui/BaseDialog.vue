<script setup lang="ts">
// Inline confirmation "dialog" — the mockups never use a centered modal/backdrop anywhere;
// confirmations are an inline bar rendered in place of the CTA/row (e.g.
// kos/decisions/ux/mockups/booking-lookup.html's cancel-confirm bar, operator-dashboard.html's
// per-row delete-confirm). Caller mounts/unmounts this via v-if at the call site — there's no
// open/backdrop/Teleport here by design.
import BaseButton from './BaseButton.vue'
import type { DialogVariant, DialogLayout } from '../../types/ui'
import { AlertTriangle } from '@lucide/vue'

withDefaults(
  defineProps<{
    message?: string
    confirmLabel?: string
    cancelLabel?: string
    variant?: DialogVariant
    layout?: DialogLayout
    /** Disables both buttons — double-submit guard while the confirm action is in flight. */
    loading?: boolean
  }>(),
  {
    message: undefined,
    confirmLabel: 'Confirm',
    cancelLabel: 'Cancel',
    variant: 'danger',
    layout: 'stacked',
    loading: false,
  },
)

defineEmits<{ confirm: []; cancel: [] }>()

defineSlots<{
  default?(): unknown
  icon?(): unknown
}>()
</script>

<template>
  <div
    v-if="layout === 'stacked'"
    class="border p-3"
    :class="variant === 'danger' ? 'border-danger bg-danger/10' : 'border-primary bg-primary/10'"
  >
    <p class="text-xs font-medium mb-2">
      <slot>{{ message }}</slot>
    </p>
    <div class="flex gap-2">
      <BaseButton
        variant="secondary"
        size="sm"
        class="flex-1 bg-background"
        :disabled="loading"
        @click="$emit('cancel')"
      >
        {{ cancelLabel }}
      </BaseButton>
      <BaseButton
        :variant="variant === 'danger' ? 'danger-filled' : 'primary'"
        size="sm"
        class="flex-1"
        :loading="loading"
        @click="$emit('confirm')"
      >
        {{ confirmLabel }}
      </BaseButton>
    </div>
  </div>

  <div
    v-else
    class="flex items-center justify-between flex-wrap gap-3 p-3"
    :class="variant === 'danger' ? 'bg-danger/5' : 'bg-primary/5'"
  >
    <div class="flex items-center gap-2">
      <slot name="icon">
        <AlertTriangle
          class="w-4 h-4 shrink-0"
          :class="variant === 'danger' ? 'text-danger' : 'text-primary'"
        />
      </slot>
      <p class="text-sm" :class="variant === 'danger' ? 'text-danger' : 'text-text'">
        <slot>{{ message }}</slot>
      </p>
    </div>
    <div class="flex gap-2 shrink-0">
      <BaseButton variant="secondary" size="sm" :disabled="loading" @click="$emit('cancel')">{{
        cancelLabel
      }}</BaseButton>
      <BaseButton
        :variant="variant === 'danger' ? 'danger-filled' : 'primary'"
        size="sm"
        :loading="loading"
        @click="$emit('confirm')"
      >
        {{ confirmLabel }}
      </BaseButton>
    </div>
  </div>
</template>
