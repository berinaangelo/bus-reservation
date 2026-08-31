<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { confirmPasswordReset } from '../../api/operator/passwordReset'
import { ApiError } from '../../api/types'
import OperatorAuthLayout from '../../layouts/OperatorAuthLayout.vue'
import PasswordInput from '../../components/ui/PasswordInput.vue'
import BaseButton from '../../components/ui/BaseButton.vue'
import BaseToast from '../../components/ui/BaseToast.vue'

const route = useRoute()
const router = useRouter()

const token = computed(() => (typeof route.query.token === 'string' ? route.query.token : null))

const password = ref('')
const passwordConfirmation = ref('')
const error = ref<string | null>(null)
const fieldErrors = ref<Record<string, string[]>>({})
const submitting = ref(false)
const succeeded = ref(false)

async function onSubmit() {
  error.value = null
  fieldErrors.value = {}

  if (password.value !== passwordConfirmation.value) {
    fieldErrors.value = { password_confirmation: ["doesn't match password"] }
    return
  }

  submitting.value = true
  try {
    await confirmPasswordReset(token.value as string, password.value, passwordConfirmation.value)
    succeeded.value = true
    setTimeout(() => router.push({ name: 'operator-login' }), 1500)
  } catch (e) {
    if (e instanceof ApiError) {
      error.value = e.message
      fieldErrors.value = e.fieldErrors ?? {}
    } else {
      error.value = 'Something went wrong. Try again.'
    }
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <OperatorAuthLayout tagline="Choose a new password for your account.">
    <template v-if="!token">
      <p class="font-display uppercase tracking-wider text-[11px] text-muted mb-4">Invalid link</p>
      <BaseToast
        variant="danger"
        message="This reset link is invalid or has expired. Request a new one to continue."
        :dismissible="false"
        class="mb-4"
      />
      <router-link
        :to="{ name: 'operator-forgot-password' }"
        class="text-xs text-muted hover:text-primary transition-colors duration-150 motion-reduce:transition-none"
      >
        Request a new link
      </router-link>
    </template>

    <template v-else-if="!succeeded">
      <p class="font-display uppercase tracking-wider text-[11px] text-muted mb-4">Set a new password</p>

      <form @submit.prevent="onSubmit">
        <BaseToast v-if="error" variant="danger" :message="error" :dismissible="false" class="mb-4" />

        <PasswordInput
          id="password"
          v-model="password"
          label="New password"
          required
          autocomplete="new-password"
          :error="fieldErrors.password?.[0]"
          class="mb-3"
        />

        <PasswordInput
          id="password_confirmation"
          v-model="passwordConfirmation"
          label="Confirm new password"
          required
          autocomplete="new-password"
          :error="fieldErrors.password_confirmation?.[0]"
          class="mb-4"
        />

        <BaseButton
          type="submit"
          variant="primary"
          class="w-full"
          :loading="submitting"
          loading-text="Updating…"
        >
          Update password
        </BaseButton>
      </form>
    </template>

    <template v-else>
      <p class="font-display uppercase tracking-wider text-[11px] text-muted mb-4">Password updated</p>
      <BaseToast
        variant="success"
        message="Password updated. Taking you to log in…"
        :dismissible="false"
      />
    </template>
  </OperatorAuthLayout>
</template>
