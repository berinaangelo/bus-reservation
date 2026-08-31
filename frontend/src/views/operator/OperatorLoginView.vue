<script setup lang="ts">
// Split Panel layout (kos/decisions/ux/mockups/operator-login.html, chosen Option B), via the
// shared OperatorAuthLayout also used by ForgotPasswordView/ResetPasswordView.
import { ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useOperatorAuthStore } from '../../stores/operatorAuth'
import { ApiError } from '../../api/types'
import OperatorAuthLayout from '../../layouts/OperatorAuthLayout.vue'
import BaseInput from '../../components/ui/BaseInput.vue'
import PasswordInput from '../../components/ui/PasswordInput.vue'
import BaseButton from '../../components/ui/BaseButton.vue'
import BaseToast from '../../components/ui/BaseToast.vue'

const email = ref('')
const password = ref('')
const error = ref<string | null>(null)
const submitting = ref(false)

const auth = useOperatorAuthStore()
const router = useRouter()
const route = useRoute()

// Set by useSessionExpiryWarning's redirect when the session lapses without the operator
// explicitly logging out.
if (route.query.reason === 'expired') {
  error.value = 'Your session expired. Please log in again.'
}

async function onSubmit() {
  error.value = null
  submitting.value = true
  try {
    await auth.login(email.value, password.value)
    const redirect =
      typeof route.query.redirect === 'string' ? route.query.redirect : { name: 'operator-routes' }
    router.push(redirect)
  } catch (e) {
    error.value = e instanceof ApiError ? e.message : 'Something went wrong. Try again.'
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <OperatorAuthLayout>
    <p class="font-display uppercase tracking-wider text-[11px] text-muted mb-4">
      Log in to continue
    </p>

    <form @submit.prevent="onSubmit">
      <BaseToast v-if="error" variant="danger" :message="error" :dismissible="false" class="mb-4" />

      <BaseInput
        id="email"
        v-model="email"
        type="email"
        label="Email"
        required
        autocomplete="username"
        class="mb-3"
      />

      <PasswordInput
        id="password"
        v-model="password"
        label="Password"
        required
        autocomplete="current-password"
        class="mb-4"
      />

      <BaseButton
        type="submit"
        variant="primary"
        class="w-full"
        :loading="submitting"
        loading-text="Logging in…"
      >
        Log in
      </BaseButton>

      <router-link
        :to="{ name: 'operator-forgot-password' }"
        class="block mt-3 text-xs text-muted hover:text-primary transition-colors duration-150 motion-reduce:transition-none"
      >
        Forgot password?
      </router-link>
    </form>
  </OperatorAuthLayout>
</template>
