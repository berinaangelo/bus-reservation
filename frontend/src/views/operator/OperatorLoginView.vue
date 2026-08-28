<script setup lang="ts">
// Standalone screen, no OperatorLayout chrome — the chosen "Split Panel" mockup
// (kos/decisions/ux/mockups/operator-login.html) has no sidebar for an unauthenticated user.
// Functional (not just a placeholder) since it's the one screen this infra pass needs working
// end-to-end to verify the auth store/guard/API client together.
import { ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useOperatorAuthStore } from '../../stores/operatorAuth'
import { ApiError } from '../../api/types'

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

      <label class="mb-1 block text-sm text-muted" for="email">Email</label>
      <input
        id="email"
        v-model="email"
        type="email"
        required
        class="mb-3 w-full border border-border bg-background px-3 py-2 text-text"
      />

      <label class="mb-1 block text-sm text-muted" for="password">Password</label>
      <input
        id="password"
        v-model="password"
        type="password"
        required
        class="mb-3 w-full border border-border bg-background px-3 py-2 text-text"
      />

      <p v-if="error" class="mb-3 text-sm text-danger">{{ error }}</p>

      <button
        type="submit"
        :disabled="submitting"
        class="w-full bg-accent px-3 py-2 font-medium text-accent-text disabled:opacity-60"
      >
        {{ submitting ? 'Logging in…' : 'Log in' }}
      </button>
    </form>
  </div>
</template>
