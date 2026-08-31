<script setup lang="ts" generic="T">
// Custom listbox — no native <select> or open-dropdown precedent exists in any mockup (only the
// closed trigger, e.g. kos/decisions/ux/mockups/operator-dashboard.html's terminal picker), and no
// floating-ui/headless-UI library is installed, so this is hand-rolled per the user's decision.
// Uses aria-activedescendant (focus stays on the trigger button) rather than roving tabindex.
import { computed, onBeforeUnmount, onMounted, ref, useId, useTemplateRef } from 'vue'
import { ChevronDown } from '@lucide/vue'
import type { SelectOption } from '../../types/ui'

const props = withDefaults(
  defineProps<{
    modelValue: T | null
    options: SelectOption<T>[]
    label?: string
    placeholder?: string
    error?: string
    disabled?: boolean
    id?: string
  }>(),
  { placeholder: 'Select…', disabled: false, label: undefined, error: undefined, id: undefined },
)

const emit = defineEmits<{ 'update:modelValue': [value: T] }>()

defineSlots<{ icon?(props: { iconClass: string }): unknown }>()

const open = ref(false)
const highlightedIndex = ref(-1)
const typeaheadBuffer = ref('')
let typeaheadTimeout: ReturnType<typeof setTimeout> | undefined

const rootEl = useTemplateRef<HTMLElement>('rootEl')
const panelEl = useTemplateRef<HTMLElement>('panelEl')

const listboxId = useId()

const selectedIndex = computed(() =>
  props.options.findIndex((opt) => opt.value === props.modelValue),
)
const selectedLabel = computed(() =>
  selectedIndex.value === -1 ? null : props.options[selectedIndex.value].label,
)

function optionId(index: number): string {
  return `${listboxId}-option-${index}`
}

function openPanel() {
  if (props.disabled || props.options.length === 0) return
  highlightedIndex.value = selectedIndex.value !== -1 ? selectedIndex.value : 0
  open.value = true
}

function closePanel() {
  open.value = false
}

function toggle() {
  if (open.value) closePanel()
  else openPanel()
}

function select(index: number) {
  const option = props.options[index]
  if (!option) return
  emit('update:modelValue', option.value)
  closePanel()
}

function clampIndex(index: number): number {
  return Math.max(0, Math.min(props.options.length - 1, index))
}

function moveHighlight(delta: number) {
  highlightedIndex.value = clampIndex(highlightedIndex.value + delta)
  scrollHighlightedIntoView()
}

function scrollHighlightedIntoView() {
  const panel = panelEl.value
  if (!panel) return
  const el = panel.querySelector<HTMLElement>(`#${CSS.escape(optionId(highlightedIndex.value))}`)
  el?.scrollIntoView({ block: 'nearest' })
}

function runTypeahead(char: string) {
  typeaheadBuffer.value += char.toLowerCase()
  clearTimeout(typeaheadTimeout)
  typeaheadTimeout = setTimeout(() => {
    typeaheadBuffer.value = ''
  }, 500)

  const match = props.options.findIndex((opt) =>
    opt.label.toLowerCase().startsWith(typeaheadBuffer.value),
  )
  if (match !== -1) {
    if (!open.value) open.value = true
    highlightedIndex.value = match
    scrollHighlightedIntoView()
  }
}

function onTriggerKeydown(event: KeyboardEvent) {
  if (props.disabled) return

  if (!open.value) {
    if (['ArrowDown', 'ArrowUp', 'Enter', ' ', 'Home', 'End'].includes(event.key)) {
      event.preventDefault()
      openPanel()
      if (event.key === 'Home') highlightedIndex.value = 0
      if (event.key === 'End') highlightedIndex.value = props.options.length - 1
    } else if (event.key.length === 1) {
      runTypeahead(event.key)
    }
    return
  }

  switch (event.key) {
    case 'ArrowDown':
      event.preventDefault()
      moveHighlight(1)
      break
    case 'ArrowUp':
      event.preventDefault()
      moveHighlight(-1)
      break
    case 'Home':
      event.preventDefault()
      highlightedIndex.value = 0
      scrollHighlightedIntoView()
      break
    case 'End':
      event.preventDefault()
      highlightedIndex.value = props.options.length - 1
      scrollHighlightedIntoView()
      break
    case 'Enter':
    case ' ':
      event.preventDefault()
      select(highlightedIndex.value)
      break
    case 'Escape':
      event.preventDefault()
      closePanel()
      break
    default:
      if (event.key.length === 1) runTypeahead(event.key)
  }
}

function onDocumentMousedown(event: MouseEvent) {
  if (!rootEl.value?.contains(event.target as Node)) closePanel()
}

onMounted(() => document.addEventListener('mousedown', onDocumentMousedown))
onBeforeUnmount(() => {
  document.removeEventListener('mousedown', onDocumentMousedown)
  clearTimeout(typeaheadTimeout)
})
</script>

<template>
  <div ref="rootEl" class="relative">
    <label
      v-if="label"
      :for="id"
      class="block font-display uppercase tracking-wider text-[11px] text-muted mb-1.5"
    >
      {{ label }}
    </label>
    <button
      :id="id"
      type="button"
      role="combobox"
      aria-haspopup="listbox"
      :aria-expanded="open"
      :aria-controls="listboxId"
      :aria-activedescendant="
        open && highlightedIndex !== -1 ? optionId(highlightedIndex) : undefined
      "
      :disabled="disabled"
      class="w-full border px-3 py-2.5 text-sm flex items-center justify-between gap-2 transition-colors duration-150 motion-reduce:transition-none"
      :class="[
        error ? 'border-danger bg-danger/5' : 'border-border bg-surface',
        disabled && 'opacity-60 cursor-not-allowed',
      ]"
      @click="toggle"
      @keydown="onTriggerKeydown"
    >
      <span
        class="flex items-center gap-2 min-w-0 truncate"
        :class="modelValue == null ? 'text-muted' : 'text-text'"
      >
        <slot name="icon" :icon-class="error ? 'text-danger' : 'text-primary'" />
        <span class="truncate">{{ selectedLabel ?? placeholder }}</span>
      </span>
      <ChevronDown
        class="w-4 h-4 text-muted shrink-0 transition-transform duration-150 motion-reduce:transition-none"
        :class="{ 'rotate-180': open }"
      />
    </button>
    <ul
      v-if="open"
      :id="listboxId"
      ref="panelEl"
      role="listbox"
      class="absolute z-10 mt-1 w-full max-h-60 overflow-y-auto border border-border bg-surface"
    >
      <li
        v-for="(opt, i) in options"
        :id="optionId(i)"
        :key="i"
        role="option"
        :aria-selected="opt.value === modelValue"
        class="px-3 py-2 text-sm cursor-pointer"
        :class="
          opt.value === modelValue
            ? 'bg-primary text-white'
            : i === highlightedIndex
              ? 'bg-background'
              : 'hover:bg-background'
        "
        @click="select(i)"
        @mousemove="highlightedIndex = i"
      >
        {{ opt.label }}
      </li>
    </ul>
    <p v-if="error" class="text-[11px] text-danger mt-1">{{ error }}</p>
  </div>
</template>
