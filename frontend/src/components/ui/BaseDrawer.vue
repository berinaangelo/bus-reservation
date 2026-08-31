<script setup lang="ts">
// Right slide-over drawer — see kos/decisions/ux/mockups/operator-dashboard.html's Add/Edit
// Route/Trip/BusUnit/FareRule drawers. Two deliberate deviations from the literal mockup markup:
//   1. Mockup shows `border-l-2 border-primary`, which is that file's own "chosen option" 2px
//      badge convention bleeding into the snippet — its own prose says "a border-l ... no
//      shadow-*". Using plain border-l border-border here.
//   2. Mockup has the *caller* dim the page itself (opacity-40 on the content wrapper). This
//      component owns its own scrim via Teleport instead, so every call site gets correct
//      dim/click-outside/focus-restore for free.
import { onBeforeUnmount, useTemplateRef, watch } from 'vue'
import { X } from '@lucide/vue'

const props = withDefaults(
  defineProps<{
    modelValue: boolean
    title: string
    /** Disables Escape + backdrop-click close, e.g. while a submit is in flight. */
    persistent?: boolean
  }>(),
  { persistent: false },
)

const emit = defineEmits<{ 'update:modelValue': [value: boolean] }>()

const panelEl = useTemplateRef<HTMLElement>('panelEl')
let previouslyFocused: HTMLElement | null = null

function close() {
  emit('update:modelValue', false)
}

function onBackdropClick() {
  if (!props.persistent) close()
}

function onKeydown(event: KeyboardEvent) {
  if (event.key === 'Escape' && !props.persistent) close()
}

watch(
  () => props.modelValue,
  (isOpen) => {
    if (isOpen) {
      previouslyFocused = document.activeElement as HTMLElement | null
      document.addEventListener('keydown', onKeydown)
      document.body.style.overflow = 'hidden'
      requestAnimationFrame(() => panelEl.value?.focus())
    } else {
      document.removeEventListener('keydown', onKeydown)
      document.body.style.overflow = ''
      previouslyFocused?.focus()
    }
  },
)

onBeforeUnmount(() => {
  document.removeEventListener('keydown', onKeydown)
  document.body.style.overflow = ''
})
</script>

<template>
  <Teleport to="body">
    <Transition
      enter-active-class="transition-opacity duration-150 motion-reduce:transition-none"
      leave-active-class="transition-opacity duration-150 motion-reduce:transition-none"
      enter-from-class="opacity-0"
      leave-to-class="opacity-0"
    >
      <div v-if="modelValue" class="fixed inset-0 bg-text/40 z-40" @mousedown="onBackdropClick" />
    </Transition>
    <Transition
      enter-active-class="transition-transform duration-150 ease-out motion-reduce:transition-none"
      leave-active-class="transition-transform duration-150 ease-out motion-reduce:transition-none"
      enter-from-class="translate-x-full"
      leave-to-class="translate-x-full"
    >
      <aside
        v-if="modelValue"
        ref="panelEl"
        tabindex="-1"
        role="dialog"
        aria-modal="true"
        :aria-label="title"
        class="fixed top-0 right-0 bottom-0 w-full sm:w-[380px] bg-background border-l border-border p-5 overflow-y-auto z-50 focus:outline-none"
      >
        <div class="flex items-center justify-between mb-5">
          <h4 class="font-display font-bold text-lg uppercase tracking-wide">{{ title }}</h4>
          <button
            type="button"
            aria-label="Close"
            class="p-2 -m-2 text-muted hover:text-primary transition-colors duration-150 motion-reduce:transition-none"
            @click="close"
          >
            <X class="w-5 h-5" />
          </button>
        </div>
        <slot />
      </aside>
    </Transition>
  </Teleport>
</template>
