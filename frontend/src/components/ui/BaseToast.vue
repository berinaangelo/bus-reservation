<script setup lang="ts">
// Inline alert banner (e.g. form-level errors) — no mockup precedent exists (only a passing
// "success toast" mention in kos/decisions/ux/color-scheme.md), so this is designed fresh, reusing
// the same colored-border + tinted-background + icon + text shape BaseDialog's inline layout
// already established. Caller controls visibility via v-if — no auto-dismiss, no global store.
import { computed } from 'vue'
import { AlertTriangle, CircleCheck, Info, X } from '@lucide/vue'
import type { ToastVariant } from '../../types/ui'

const props = withDefaults(
  defineProps<{
    variant?: ToastVariant
    title?: string
    message?: string
    dismissible?: boolean
  }>(),
  { variant: 'danger', dismissible: true, title: undefined, message: undefined },
)

defineEmits<{ dismiss: [] }>()

defineSlots<{
  default?(): unknown
  icon?(props: { iconClass: string }): unknown
}>()

const classesByVariant: Record<ToastVariant, { container: string; icon: string }> = {
  danger: { container: 'border-danger bg-danger/10', icon: 'text-danger' },
  success: { container: 'border-success bg-success/10', icon: 'text-success' },
  warning: { container: 'border-warning bg-warning/10', icon: 'text-warning' },
  // Deliberately neutral: no dedicated "info" color token exists, and color-scheme.md already
  // flags primary-green doubling as "success" as a collision risk — reusing primary here too
  // would compound that.
  info: { container: 'border-border bg-surface', icon: 'text-muted' },
}

const iconByVariant: Record<ToastVariant, typeof AlertTriangle> = {
  danger: AlertTriangle,
  warning: AlertTriangle,
  success: CircleCheck,
  info: Info,
}

const variantClasses = computed(() => classesByVariant[props.variant])
const variantIcon = computed(() => iconByVariant[props.variant])
</script>

<template>
  <div role="alert" class="flex items-start gap-3 border p-3" :class="variantClasses.container">
    <slot name="icon" :icon-class="variantClasses.icon">
      <component :is="variantIcon" class="w-4 h-4 shrink-0 mt-0.5" :class="variantClasses.icon" />
    </slot>
    <div class="flex-1 min-w-0">
      <p v-if="title" class="text-sm font-semibold text-text mb-0.5">{{ title }}</p>
      <p class="text-sm text-text">
        <slot>{{ message }}</slot>
      </p>
    </div>
    <button
      v-if="dismissible"
      type="button"
      aria-label="Dismiss"
      class="shrink-0 -m-1 p-1 text-muted hover:text-primary transition-colors duration-150 motion-reduce:transition-none"
      @click="$emit('dismiss')"
    >
      <X class="w-4 h-4" />
    </button>
  </div>
</template>
