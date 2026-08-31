<script setup lang="ts">
import { ref } from 'vue'
import { requestPasswordReset } from '../../api/operator/passwordReset'
import { ApiError } from '../../api/types'
import OperatorAuthLayout from '../../layouts/OperatorAuthLayout.vue'
import BaseInput from '../../components/ui/BaseInput.vue'
import BaseButton from '../../components/ui/BaseButton.vue'
import BaseToast from '../../components/ui/BaseToast.vue'

const email = ref('')
const error = ref<string | null>(null)
const submitting = ref(false)
// Set on any 200, regardless of whether the email was actually found -- the backend's response is
// the same generic message either way, so the UI can't distinguish "sent" from "no such account"
// and must not try to.
const submitted = ref(false)

async function onSubmit() {
  error.value = null
  submitting.value = true
  try {
    await requestPasswordReset(email.value)
    submitted.value = true
  } catch (e) {
    error.value = e instanceof ApiError ? e.message : 'Something went wrong. Try again.'
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <OperatorAuthLayout tagline="Enter your email and we'll send you a link to reset your password.">
    <template v-if="submitted">
      <p class="font-display uppercase tracking-wider text-[11px] text-muted mb-4">Check your email</p>
      <BaseToast
        variant="success"
        message="If that email is registered, we've sent password reset instructions."
        :dismissible="false"
        class="mb-4"
      />
      <router-link
        :to="{ name: 'operator-login' }"
        class="text-xs text-muted hover:text-primary transition-colors duration-150 motion-reduce:transition-none"
      >
        Back to log in
      </router-link>
    </template>

    <template v-else>
      <p class="font-display uppercase tracking-wider text-[11px] text-muted mb-4">Reset your password</p>

      <form @submit.prevent="onSubmit">
        <BaseToast v-if="error" variant="danger" :message="error" :dismissible="false" class="mb-4" />

        <BaseInput
          id="email"
          v-model="email"
          type="email"
          label="Email"
          required
          autocomplete="username"
          class="mb-4"
        />

        <BaseButton
          type="submit"
          variant="primary"
          class="w-full"
          :loading="submitting"
          loading-text="Sending…"
        >
          Send reset link
        </BaseButton>

        <router-link
          :to="{ name: 'operator-login' }"
          class="block mt-3 text-xs text-muted hover:text-primary transition-colors duration-150 motion-reduce:transition-none"
        >
          Back to log in
        </router-link>
      </form>
    </template>
  </OperatorAuthLayout>
</template>
