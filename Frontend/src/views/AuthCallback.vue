<script setup>
import { onMounted } from 'vue'

onMounted(() => {
  window.location.href = '/'
})
</script>

<template>
  <div class="flex min-h-screen items-center justify-center bg-background">
    <p class="text-sm text-muted-foreground animate-pulse">Signing you in…</p>
  </div>
</template>