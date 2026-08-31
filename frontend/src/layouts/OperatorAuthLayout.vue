<script setup lang="ts">
// Shared chrome for the unauthenticated operator screens (login, forgot/reset password) --
// the chosen "Split Panel" mockup (kos/decisions/ux/mockups/operator-login.html, Option B).
// Brand panel on the left, form slot on the right, so every auth screen looks like one product.
withDefaults(
  defineProps<{
    tagline?: string
  }>(),
  {
    tagline:
      'Manage your own routes, trips, fleet and fares, and view the trip manifest at boarding — scoped to your operator account only.',
  },
)
</script>

<template>
  <div class="flex min-h-screen items-center justify-center bg-background p-4">
    <div class="w-full max-w-3xl border-2 border-primary bg-background grid grid-cols-1 md:grid-cols-2">
      <div class="bg-primary text-white p-6 sm:p-10 flex flex-col justify-center">
        <span class="font-display font-bold text-2xl leading-none mb-2">TS</span>
        <p class="font-display uppercase tracking-wide text-sm font-semibold mb-2">Operator Console</p>
        <p class="text-sm text-white/80 leading-relaxed max-w-xs">{{ tagline }}</p>
      </div>
      <div class="p-6 sm:p-10 flex items-center">
        <div class="w-full">
          <slot />
        </div>
      </div>
    </div>
  </div>
</template>
