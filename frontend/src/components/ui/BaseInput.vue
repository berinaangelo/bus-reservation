<script setup lang="ts">
// Base text input — see kos/decisions/ux/mockups/booking-lookup.html (reference-code field) and
// seat-selection-passenger-details.html (contact number field): label above, icon+input in one
// inline row inside a single bordered box (icon is NOT absolutely positioned). Focus ring lives on
// the outer wrapper (focus-within), not the <input> itself.
withDefaults(
  defineProps<{
    modelValue: string
    type?: 'text' | 'email' | 'password' | 'date' | 'datetime-local' | 'tel' // 'password' is normally reached via PasswordInput
    label?: string
    placeholder?: string
    /** Presence = error state; also rendered as helper text below the field. */
    error?: string
    disabled?: boolean
    required?: boolean
    id?: string
    name?: string
    autocomplete?: string
    /** Only meaningful for type="date"/"datetime-local" (or "number", if ever needed). */
    min?: string
    max?: string
  }>(),
  {
    type: 'text',
    label: undefined,
    placeholder: undefined,
    error: undefined,
    disabled: false,
    required: false,
    id: undefined,
    name: undefined,
    autocomplete: undefined,
    min: undefined,
    max: undefined,
  },
)

defineEmits<{ 'update:modelValue': [value: string] }>()

defineSlots<{
  leading?(props: { iconClass: string }): unknown
  trailing?(props: { iconClass: string }): unknown
}>()
</script>

<template>
  <div>
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
          :name="name"
          :type="type"
          :value="modelValue"
          :placeholder="placeholder"
          :disabled="disabled"
          :required="required"
          :autocomplete="autocomplete"
          :min="min"
          :max="max"
          class="w-full min-w-0 bg-transparent text-base font-mono tracking-wide text-text placeholder:text-muted placeholder:font-sans focus:outline-none disabled:cursor-not-allowed disabled:text-muted"
          @input="$emit('update:modelValue', ($event.target as HTMLInputElement).value)"
        />
        <slot name="trailing" :icon-class="error ? 'text-danger' : 'text-muted'" />
      </div>
    </div>
    <p v-if="error" class="text-[11px] text-danger mt-1">{{ error }}</p>
  </div>
</template>
