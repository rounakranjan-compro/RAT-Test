<script setup>
import {
  Card,
  CardHeader,
  CardTitle,
  CardContent,
} from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"

const props = defineProps({
  error: {
    type: Object,
    default: null,
  },
})
</script>

<template>
  <Card
    v-if="error"
    class="border-slate-800
           bg-gradient-to-b from-slate-900 to-slate-950"
  >
    <CardHeader
      class="flex flex-row items-center justify-between
             border-b border-slate-800"
    >
      <CardTitle class="flex items-center gap-2 text-white">
        📋 Error Log
      </CardTitle>
    </CardHeader>
    <CardContent class="pt-4 overflow-auto">
      <pre
        class="text-wrap"
      >
     {{ JSON.stringify(error, null, 2) }}
      </pre>
    </CardContent>
  </Card>
</template>
