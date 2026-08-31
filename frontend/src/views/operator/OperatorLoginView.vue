<script setup lang="ts">
// Standalone screen, no OperatorLayout chrome — the chosen "Split Panel" mockup
// (kos/decisions/ux/mockups/operator-login.html) has no sidebar for an unauthenticated user.
// Functional (not just a placeholder) since it's the one screen this infra pass needs working
// end-to-end to verify the auth store/guard/API client together. Refactored to consume the base
// UI kit (frontend/src/components/ui/) — this was its original reference markup.
import { ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useOperatorAuthStore } from '../../stores/operatorAuth'
import { ApiError } from '../../api/types'
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
  <div class="flex min-h-screen items-center justify-center bg-background">
    <form class="w-full max-w-sm border border-border bg-surface p-6" @submit.prevent="onSubmit">
      <h1 class="mb-4 font-display text-2xl font-bold text-primary">Operator Console</h1>

      <BaseToast v-if="error" variant="danger" :message="error" :dismissible="false" class="mb-3" />

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
    </form>
  </div>
</template>
