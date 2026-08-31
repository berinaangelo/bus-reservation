<script setup lang="ts">
// Base button — see kos/decisions/ux/mockups/trip-search.html (primary CTA + loading state),
// booking-lookup.html (danger outline + danger-filled confirm-bar buttons), and
// operator-dashboard.html (secondary outline drawer "Cancel"). Sharp corners, no shadow, filled
// by default, per kos/decisions/ux/shape-and-surface.md.
import { computed } from 'vue'
import type { ButtonVariant, ButtonSize } from '../../types/ui'

const props = withDefaults(
  defineProps<{
    variant?: ButtonVariant
    size?: ButtonSize
    type?: 'button' | 'submit' | 'reset'
    disabled?: boolean
    loading?: boolean
    /** Shown instead of the default slot while loading. Omitted = keep slot content, just add the spinner. */
    loadingText?: string
    /** 44px fixed square touch target (Fitts's Law) for icon-only row actions. Caller must supply aria-label. */
    iconOnly?: boolean
  }>(),
  {
    variant: 'primary',
    size: 'md',
    type: 'button',
    disabled: false,
    loading: false,
    loadingText: undefined,
    iconOnly: false,
  },
)

const isDisabled = computed(() => props.disabled || props.loading)

const paddingByVariant: Record<ButtonVariant, Record<ButtonSize, string>> = {
  primary: { md: 'px-6 py-3 text-sm', sm: 'px-4 py-2.5 text-xs' },
  secondary: { md: 'px-5 py-2 text-sm', sm: 'px-3 py-2 text-xs' },
  danger: { md: 'px-4 py-3 text-xs', sm: 'px-3 py-2 text-xs' },
  'danger-filled': { md: 'px-3 py-2.5 text-xs', sm: 'px-3 py-2 text-xs' },
}

function colorClasses(variant: ButtonVariant): string {
  switch (variant) {
    case 'primary':
      return isDisabled.value
        ? 'bg-accent/70 text-[#1E2925] cursor-not-allowed'
        : 'bg-accent text-[#1E2925] hover:bg-[#d97722] focus:ring-primary'
    case 'secondary':
      return isDisabled.value
        ? 'bg-border text-muted'
        : 'border border-border text-text hover:border-primary hover:text-primary focus:ring-primary'
    case 'danger':
      return isDisabled.value
        ? 'bg-border text-muted'
        : 'border border-danger text-danger hover:bg-danger/10 focus:ring-danger'
    case 'danger-filled':
      return isDisabled.value
        ? 'bg-danger/70 text-white cursor-not-allowed'
        : 'bg-danger text-white hover:bg-danger/90 focus:ring-danger'
  }
}

const buttonClass = computed(() => {
  if (props.iconOnly) {
    return [
      'w-11 h-11 p-0 shrink-0 border border-border bg-background text-muted',
      isDisabled.value
        ? 'opacity-60 cursor-not-allowed'
        : 'hover:text-primary hover:border-primary',
    ]
  }
  return [paddingByVariant[props.variant][props.size], colorClasses(props.variant)]
})

const spinnerSize = computed(() => (props.size === 'sm' ? 'w-3.5 h-3.5' : 'w-4 h-4'))
</script>

<template>
  <button
    :type="type"
    :disabled="isDisabled"
    :aria-busy="loading"
    class="font-display uppercase tracking-wide font-semibold inline-flex items-center justify-center gap-2 transition-colors duration-150 motion-reduce:transition-none focus:outline-none focus:ring-2 disabled:cursor-not-allowed"
    :class="buttonClass"
  >
    <svg
      v-if="loading"
      :class="spinnerSize"
      class="animate-spin"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
    >
      <path d="M21 12a9 9 0 1 1-6.219-8.56" />
    </svg>
    <template v-if="loading && loadingText">{{ loadingText }}</template>
    <slot v-else />
  </button>
</template>
