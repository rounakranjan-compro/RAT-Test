<script setup>
import MetaCard from "./MetaCard.vue"

defineProps({
  environment: {
    type: String,
    required: true 
  },
  duration: String,
  startedAt: String,
  finishedAt: String,
})
</script>

<template>
  <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
   <MetaCard label="Environment" :value="environment" />
   <MetaCard label="Duration" :value="duration" />
   <MetaCard label="Started At" :value="startedAt" />
   <MetaCard label="Finished At" :value="finishedAt" />
  </div>
</template>
