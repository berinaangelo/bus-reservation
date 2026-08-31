<script setup lang="ts">
import { useRouter } from 'vue-router'
import { useOperatorAuthStore } from '../../stores/operatorAuth'

const router = useRouter()
const auth = useOperatorAuthStore()

const navItems = [
  { to: { name: 'operator-routes' }, label: 'Routes' },
  { to: { name: 'operator-trips' }, label: 'Trips' },
  { to: { name: 'operator-bus-units' }, label: 'Bus Units' },
  { to: { name: 'operator-fare-rules' }, label: 'Fare Rules' },
  { to: { name: 'operator-staff' }, label: 'Staff' },
]

async function logout() {
  await auth.logout()
  router.push({ name: 'operator-login' })
}
</script>

<template>
  <nav class="flex h-full w-56 shrink-0 flex-col border-r border-border bg-surface p-4">
    <p class="mb-4 font-display text-lg font-bold text-primary">Operator Console</p>
    <router-link
      v-for="item in navItems"
      :key="item.label"
      :to="item.to"
      class="rounded-none px-3 py-2 text-sm text-text hover:bg-background"
      active-class="bg-background font-medium text-primary"
    >
      {{ item.label }}
    </router-link>
    <button
      type="button"
      class="mt-auto px-3 py-2 text-left text-sm text-muted hover:text-danger"
      @click="logout"
    >
      Log out
    </button>
  </nav>
</template>
