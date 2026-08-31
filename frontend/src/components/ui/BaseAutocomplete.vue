<script setup lang="ts" generic="T">
// Server-driven combobox — see kos/decisions/ux/mockups/trip-search.html's From/To fields: a
// plain text input with a leading pin icon (no dropdown chevron), unlike BaseSelect's
// closed-trigger style. Reuses BaseInput's field-row classes and BaseSelect's dropdown-panel
// classes for visual consistency, but owns its <input> directly (role="combobox" + friends need
// the native element, which a wrapped BaseInput doesn't currently expose).
//
// Two v-models: `modelValue` (the committed value) and `query` (the displayed/typed text) — kept
// separate so a caller can resync both together (e.g. a swap-fields button).
import { onBeforeUnmount, onMounted, ref, shallowRef, useId, useTemplateRef } from 'vue'
import type { SelectOption } from '../../types/ui'

const props = withDefaults(
  defineProps<{
    modelValue: T | null
    query: string
    loader: (query: string) => Promise<SelectOption<T>[]>
    label?: string
    placeholder?: string
    error?: string
    disabled?: boolean
    id?: string
    debounceMs?: number
    noResultsText?: string
  }>(),
  {
    placeholder: 'Search…',
    debounceMs: 300,
    noResultsText: 'No matches',
    disabled: false,
    label: undefined,
    error: undefined,
    id: undefined,
  },
)

const emit = defineEmits<{
  'update:modelValue': [value: T | null]
  'update:query': [value: string]
}>()

defineSlots<{ leading?(props: { iconClass: string }): unknown }>()

const open = ref(false)
// shallowRef: options is always replaced wholesale on each load, never deeply mutated — this also
// sidesteps a Vue+generics rough edge where a deep ref<SelectOption<T>[]> reports `option.value`
// as UnwrapRef<T> instead of T for an unconstrained generic T.
const options = shallowRef<SelectOption<T>[]>([])
const loading = ref(false)
const loadError = ref<string | null>(null)
const highlightedIndex = ref(-1)
const hasLoadedOnce = ref(false)

const rootEl = useTemplateRef<HTMLElement>('rootEl')
const inputEl = useTemplateRef<HTMLInputElement>('inputEl')
const listboxId = useId()

let requestToken = 0
let debounceHandle: ReturnType<typeof setTimeout> | undefined

function optionId(index: number): string {
  return `${listboxId}-option-${index}`
}

async function runLoad(query: string) {
  const token = ++requestToken
  loading.value = true
  loadError.value = null
  try {
    const result = await props.loader(query)
    if (token !== requestToken) return // superseded by a newer call — drop this stale response
    options.value = result
    highlightedIndex.value = result.length ? 0 : -1
  } catch {
    if (token !== requestToken) return
    options.value = []
    loadError.value = "Couldn't load results. Try again."
  } finally {
    if (token === requestToken) loading.value = false
  }
  hasLoadedOnce.value = true
}

function scheduleLoad(query: string) {
  clearTimeout(debounceHandle)
  debounceHandle = setTimeout(() => runLoad(query), props.debounceMs)
}

function onInput(event: Event) {
  const value = (event.target as HTMLInputElement).value
  emit('update:query', value)
  emit('update:modelValue', null) // typing away from a prior pick un-commits it
  open.value = true
  scheduleLoad(value)
}

// select() below restores focus to the input after closing the panel, which fires a real native
// `focus` event straight back into onFocus() — without this guard that would immediately reopen
// the panel it just closed.
let suppressNextFocusOpen = false

function onFocus() {
  if (suppressNextFocusOpen) {
    suppressNextFocusOpen = false
    return
  }
  open.value = true
  if (!hasLoadedOnce.value) runLoad(props.query)
}

function select(index: number) {
  const option = options.value[index]
  if (!option) return
  emit('update:modelValue', option.value)
  emit('update:query', option.label)
  open.value = false
  suppressNextFocusOpen = true
  inputEl.value?.focus()
}

function onKeydown(event: KeyboardEvent) {
  if (props.disabled) return

  if (event.key === 'ArrowDown') {
    event.preventDefault()
    if (!open.value) {
      open.value = true
      if (!hasLoadedOnce.value) runLoad(props.query)
      return
    }
    highlightedIndex.value = Math.min(highlightedIndex.value + 1, options.value.length - 1)
  } else if (event.key === 'ArrowUp') {
    event.preventDefault()
    highlightedIndex.value = Math.max(highlightedIndex.value - 1, 0)
  } else if (event.key === 'Enter') {
    if (open.value && highlightedIndex.value !== -1) {
      event.preventDefault()
      select(highlightedIndex.value)
    }
  } else if (event.key === 'Escape') {
    open.value = false
  }
}

function onDocumentMousedown(event: MouseEvent) {
  if (!rootEl.value?.contains(event.target as Node)) open.value = false
}

onMounted(() => document.addEventListener('mousedown', onDocumentMousedown))
onBeforeUnmount(() => {
  document.removeEventListener('mousedown', onDocumentMousedown)
  clearTimeout(debounceHandle)
})
</script>

<template>
  <div ref="rootEl" class="relative">
    <div
      class="border p-3 focus-within:ring-2 focus-within:ring-primary transition-colors duration-150 motion-reduce:transition-none"
      :class="[
        error ? 'border-danger bg-danger/5' : 'border-border bg-surface',
        disabled && 'opacity-60 cursor-not-allowed',
      ]"
    >
      <label
        v-if="label"
        :for="id"
        class="block font-display uppercase tracking-wider text-[11px] text-muted mb-1"
      >
        {{ label }}
      </label>
      <div class="flex items-center gap-2">
        <slot name="leading" :icon-class="error ? 'text-danger' : 'text-primary'" />
        <input
          :id="id"
          ref="inputEl"
          type="text"
          role="combobox"
          aria-autocomplete="list"
          :aria-expanded="open"
          :aria-controls="listboxId"
          :aria-activedescendant="
            open && highlightedIndex !== -1 ? optionId(highlightedIndex) : undefined
          "
          :value="query"
          :placeholder="placeholder"
          :disabled="disabled"
          autocomplete="off"
          class="w-full min-w-0 bg-transparent text-base font-medium text-text placeholder:text-muted placeholder:font-normal focus:outline-none disabled:cursor-not-allowed disabled:text-muted"
          @input="onInput"
          @focus="onFocus"
          @keydown="onKeydown"
        />
        <svg
          v-if="loading"
          class="w-4 h-4 text-muted shrink-0 animate-spin"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
        >
          <path d="M21 12a9 9 0 1 1-6.219-8.56" />
        </svg>
      </div>
    </div>
    <ul
      v-if="open"
      :id="listboxId"
      role="listbox"
      class="absolute z-10 mt-1 w-full max-h-60 overflow-y-auto border border-border bg-surface"
    >
      <li v-if="loadError" class="px-3 py-2 text-sm text-danger">{{ loadError }}</li>
      <template v-else-if="!loading || options.length">
        <li v-if="options.length === 0" class="px-3 py-2 text-sm text-muted">
          {{ noResultsText }}
        </li>
        <li
          v-for="(opt, i) in options"
          :id="optionId(i)"
          :key="i"
          role="option"
          :aria-selected="i === highlightedIndex"
          class="px-3 py-2 text-sm cursor-pointer"
          :class="i === highlightedIndex ? 'bg-background' : 'hover:bg-background'"
          @click="select(i)"
          @mousemove="highlightedIndex = i"
        >
          {{ opt.label }}
        </li>
      </template>
    </ul>
    <p v-if="error" class="text-[11px] text-danger mt-1">{{ error }}</p>
  </div>
</template>
