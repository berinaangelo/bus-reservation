<script setup lang="ts">
// Password field. No mockup precedent exists for a real <input type="password"> or a visibility
// toggle (mockups show password fields as static bulleted <div>s) — this wraps BaseInput and fills
// its #trailing slot with a new eye/eye-off toggle, keeping the same icon-slot convention.
import { ref } from 'vue'
import { Eye, EyeOff } from '@lucide/vue'
import BaseInput from './BaseInput.vue'

withDefaults(
  defineProps<{
    modelValue: string
    label?: string
    placeholder?: string
    error?: string
    disabled?: boolean
    required?: boolean
    id?: string
    name?: string
    autocomplete?: string
  }>(),
  {
    label: undefined,
    placeholder: undefined,
    error: undefined,
    disabled: false,
    required: false,
    id: undefined,
    name: undefined,
    autocomplete: undefined,
  },
)

defineEmits<{ 'update:modelValue': [value: string] }>()

const visible = ref(false)
</script>

<template>
  <BaseInput
    :id="id"
    :model-value="modelValue"
    :type="visible ? 'text' : 'password'"
    :label="label"
    :placeholder="placeholder"
    :error="error"
    :disabled="disabled"
    :required="required"
    :name="name"
    :autocomplete="autocomplete"
    @update:model-value="$emit('update:modelValue', $event)"
  >
    <template #trailing>
      <button
        type="button"
        class="shrink-0"
        :aria-label="visible ? 'Hide password' : 'Show password'"
        @click="visible = !visible"
      >
        <EyeOff
          v-if="visible"
          class="w-4 h-4 text-muted hover:text-primary transition-colors duration-150 motion-reduce:transition-none"
        />
        <Eye
          v-else
          class="w-4 h-4 text-muted hover:text-primary transition-colors duration-150 motion-reduce:transition-none"
        />
      </button>
    </template>
  </BaseInput>
</template>
