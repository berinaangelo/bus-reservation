<script setup lang="ts">
import AppHeader from '../components/layout/AppHeader.vue'
</script>

<template>
  <div class="flex min-h-screen flex-col">
    <AppHeader />
    <main class="mx-auto w-full max-w-5xl flex-1 px-4 py-6">
      <router-view />
    </main>
  </div>
</template>
