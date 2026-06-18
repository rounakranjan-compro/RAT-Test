<script setup>
import {
  Card,
  CardHeader,
  CardTitle,
  CardContent,
} from "@/components/ui/card"

defineProps({
  label: {
    type: String,
    required: true
  },
  value: {
    type: String,
    required: true
  }
})
</script>

<template>
  <Card
    class="border-slate-800
           bg-[#1c2333]
"
  >
    <CardHeader class="pb-2">
      <CardTitle
        class="text-xs font-medium tracking-wide
               text-slate-400 uppercase"
      >
        {{ label }}
      </CardTitle>
    </CardHeader>

    <CardContent>
      <p class="text-xl font-semibold text-white">
        {{ value }}
      </p>
    </CardContent>
  </Card>
</template>
