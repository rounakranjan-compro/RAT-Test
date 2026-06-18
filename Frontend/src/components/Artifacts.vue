<script setup>
import {
  Card,
  CardHeader,
  CardTitle,
  CardContent,
} from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"

import ArtifactItem from "./ArtifactItem.vue"

defineProps({
  artifacts: {
    type: Array,
    required: true
  }
})

const label = kind => {
  switch (kind) {
    case "screenshot":
      return { title: "Screenshot (on failure)", icon: "🖼️" }
    case "video":
      return { title: "Execution Video", icon: "🎥" }
    case "trace":
      return { title: "Trace File", icon: "📊" }
    default:
      return { title: kind, icon: "📦" }
  }
}
</script>

<template>
  <Card
    v-if="artifacts.length"
    class="border-slate-800
           bg-gradient-to-b from-slate-900 to-slate-950"
  >
    <CardHeader
      class="flex flex-row items-center justify-between"
    >
      <CardTitle class="flex items-center gap-2 text-white">
        📦 Artifacts
      </CardTitle>

      <Badge variant="info" class="uppercase tracking-wide">
        {{ artifacts.length }} files generated
      </Badge>
    </CardHeader>
    <CardContent class="space-y-4">
     <ArtifactItem
  v-for="item in artifacts"
  :key="item.kind"
  :title="label(item.kind).title"
  :path="item.url"
  :icon="label(item.kind).icon"
/>
    </CardContent>
  </Card>
</template>
