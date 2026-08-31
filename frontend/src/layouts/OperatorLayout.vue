<script setup lang="ts">
import OperatorSidebar from '../components/layout/OperatorSidebar.vue'
import BaseToast from '../components/ui/BaseToast.vue'
import BaseButton from '../components/ui/BaseButton.vue'
import { useSessionExpiryWarning } from '../composables/useSessionExpiryWarning'

const { showWarning, renewing, renew } = useSessionExpiryWarning()
</script>

<template>
  <div class="flex min-h-screen">
    <OperatorSidebar />
    <main class="flex-1 p-6">
      <BaseToast v-if="showWarning" variant="warning" :dismissible="false" class="mb-4">
        <div class="flex items-center justify-between gap-3 flex-wrap">
          <span>Your session is about to expire.</span>
          <BaseButton variant="secondary" size="sm" :loading="renewing" @click="renew">
            Stay logged in
          </BaseButton>
        </div>
      </BaseToast>
      <router-view />
    </main>
  </div>
</template>
