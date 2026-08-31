<script setup lang="ts">
// Empty-state card — extracted from kos/decisions/ux/mockups/trip-search.html's zero-results card
// (full-page/rider context, size="lg") and operator-dashboard.html's empty-list card
// (table-embedded/operator context, size="md"). Reused wherever a list/search/report has no
// results.
import { computed } from 'vue'

const props = withDefaults(
  defineProps<{
    title: string
    message?: string
    size?: 'md' | 'lg'
  }>(),
  { size: 'lg', message: undefined },
)

defineSlots<{
  icon?(props: { iconClass: string }): unknown
  action?(): unknown
}>()

const iconClass = computed(() => `text-muted ${props.size === 'lg' ? 'w-10 h-10' : 'w-8 h-8'}`)
</script>

<template>
  <div
    class="border border-border bg-surface flex flex-col items-center text-center gap-3"
    :class="size === 'lg' ? 'p-8' : 'py-16 px-6'"
  >
    <slot name="icon" :icon-class="iconClass" />
    <h4
      class="font-display font-bold"
      :class="size === 'lg' ? 'text-xl' : 'text-base uppercase tracking-wide'"
    >
      {{ title }}
    </h4>
    <p v-if="message" class="text-sm text-muted" :class="size === 'lg' ? 'max-w-sm' : 'max-w-xs'">
      {{ message }}
    </p>
    <slot name="action" />
  </div>
</template>
