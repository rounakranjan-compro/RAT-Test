<script setup>
import { computed, ref } from "vue"
import { Badge } from "@/components/ui/badge"
import { useDateFormatter } from '@/composables/useDateFormatter'

const props = defineProps({
  status: {
    type: String,
    default: "NEW"
  },
  runId: {
    type: String,
    default: "#-"
  },
  runTime: {
    type: String,
    default: "-"
  },
})

const error = ref(null)
const { formatDateTime } = useDateFormatter()

const normalizedStatus = computed(() => {
  try {
    if (!props.status) return "NEW"
    const status = props.status.toUpperCase().trim()
    // Handle different status values from your API
    if (["PASSED", "PASS"].includes(status)) return "PASSED"
    if (["FAILED", "FAIL"].includes(status)) return "FAILED"
    if (["RUNNING", "IN_PROGRESS"].includes(status)) return "RUNNING"
    return "NEW"
  } catch (err) {
    error.value = "Error processing status"
    return "NEW"
  }
})

const isPassed = computed(() => normalizedStatus.value === "PASSED")
const isFailed = computed(() => normalizedStatus.value === "FAILED")
const isRunning = computed(() => normalizedStatus.value === "RUNNING")
const isNew = computed(() => normalizedStatus.value === "NEW")

const containerClasses = computed(() => {
  try {
    if (isPassed.value) {
      return "border-emerald-600/40 from-emerald-900/40 to-emerald-950"
    }
    if (isFailed.value) {
      return "border-red-600/40 from-red-900/40 to-red-950"
    }
    if (isRunning.value) {
      return "border-blue-600/40 from-blue-900/40 to-blue-950"
    }
    return "border-slate-600/40 from-slate-900/40 to-slate-950"
  } catch {
    return "border-slate-600/40 from-slate-900/40 to-slate-950"
  }
})

const iconClasses = computed(() => {
  if (isPassed.value) return "bg-emerald-600"
  if (isFailed.value) return "bg-red-600"
  if (isRunning.value) return "bg-blue-600"
  return "bg-slate-600"
})

const iconSymbol = computed(() => {
  if (isPassed.value) return "✔"
  if (isFailed.value) return "✕"
  if (isRunning.value) return "⟳"
  return "○"
})

const statusText = computed(() => {
  if (isPassed.value) return "Test Passed"
  if (isFailed.value) return "Test Failed"
  if (isRunning.value) return "Test Running"
  return "Not Run Yet"
})

const badgeText = computed(() => normalizedStatus.value)

const badgeClasses = computed(() => {
  if (isPassed.value) return "bg-emerald-600"
  if (isFailed.value) return "bg-red-600"
  if (isRunning.value) return "bg-blue-600 animate-pulse"
  return "bg-slate-600"
})

const runInfo = computed(() => {
  try {
    const id = props.runId || "—"
    const time = props.runTime || "—"
    
    // Use the composable to format the time
    let formattedTime = time
    if (time !== "—") {
      try {
        formattedTime = formatDateTime(new Date(time))
      } catch {
        formattedTime = time
      }
    }
    
    return `Run ${id} • ${formattedTime}`
  } catch {
    return "Run info unavailable"
  }
})
</script>

<template>
  <div v-if="error" class="rounded-xl border border-red-600/40 bg-red-900/20 px-6 py-5 text-red-300">
    {{ error }}
  </div>

  <div
    v-else
    class="rounded-xl border px-6 py-5
           bg-gradient-to-b
           flex flex-col gap-4
           sm:flex-row sm:items-center sm:justify-between"
    :class="containerClasses"
  >
    <div class="flex items-center gap-4">
      <div
        class="flex h-12 w-12 items-center justify-center rounded-full"
        :class="iconClasses"
      >
        <span class="text-xl text-white">
          {{ iconSymbol }}
        </span>
      </div>
      <div>
        <h3 class="text-lg font-semibold text-white">
          {{ statusText }}
        </h3>
        <p class="text-sm text-slate-400">
          {{ runInfo }}
        </p>
      </div>
    </div>
    <Badge
      :class="badgeClasses"
      class="uppercase tracking-wide self-start sm:self-auto"
    >
      {{ badgeText }}
    </Badge>
  </div>
</template>