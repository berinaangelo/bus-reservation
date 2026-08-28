<script setup lang="ts">
import OperatorSidebar from '../components/layout/OperatorSidebar.vue'
</script>

<template>
  <div class="flex min-h-screen">
    <OperatorSidebar />
    <main class="flex-1 p-6">
      <router-view />
    </main>
  </div>
</template>
