<script setup>
import { reactive } from "vue"
import RunResultHeader from "./RunResultHeader.vue"
import RunResultStatus from "./RunResultStatus.vue"
import RunResultMeta from "./RunResultMeta.vue"
import ErrorLog from "./ErrorLog.vue"  
import Artifacts from "./Artifacts.vue"
import RunHistory from "./RunHistory.vue"
import { Card, CardHeader, CardContent } from "@/components/ui/card"    
import { useTestStore } from '@/stores/testStore'
import { storeToRefs } from 'pinia'
import { ref,computed, watch, onMounted } from "vue"

const testStore = useTestStore()
const { selectedTest, testRuns } = storeToRefs(testStore)
const loading = ref(false)
const fetchError = ref(null)

const loadRuns = async () => {
  if (!selectedTest.value?.id) return
  loading.value = true
  try {
    await testStore.fetchTestRuns(selectedTest.value.id)
  } finally {
    loading.value = false
  }
}

onMounted(loadRuns)
watch(selectedTest, loadRuns)



// Computed properties for RunResultStatus
const runStatus = computed(() => selectedTest.value?.status || "NEW")
const runId = computed(() => selectedTest.value?.id ? `#${selectedTest.value.id}` : "#-")
const runTime = computed(() => selectedTest.value?.lastRun || "-")

// Computed properties for RunResultMeta
const environment = computed(() => selectedTest.value?.environment || "-")
const duration = computed(() => selectedTest.value?.duration || "0s")
const startedAt = computed(() => {
  if (!selectedTest.value?.startedAt) return "-"
  
  // Format time as HH:MM:SS
  const date = new Date(selectedTest.value.startedAt)
  return date.toLocaleTimeString('en-US', { 
    hour12: false, 
    hour: '2-digit', 
    minute: '2-digit', 
    second: '2-digit' 
  })
})
const finishedAt = computed(() => {
  if (!selectedTest.value?.finishedAt) return "-"
  
  // Format time as HH:MM:SS
  const date = new Date(selectedTest.value.finishedAt)
  return date.toLocaleTimeString('en-US', { 
    hour12: false, 
    hour: '2-digit', 
    minute: '2-digit', 
    second: '2-digit' 
  })
})

const artifacts = computed(() => selectedTest.value?.artifacts || [])

const errorArtifact = computed(() =>
  artifacts.value.find(a => a.kind === "error_log")
)

const fileArtifacts = computed(() =>
  artifacts.value.filter(a => a.kind !== "error_log")
)
</script>

<template>
  <div class="
 w-full lg:w-[100%] ">
    <RunResultHeader :title="selectedTest?.title"/>
    <div
      class="border border-slate-800
            bg-[#161b26]
             p-6 space-y-6"
    >
      <RunResultStatus
        :status="runStatus"
        :run-id="runId"
        :run-time="runTime"
      />
   
      <RunResultMeta
        :environment="environment"
        :duration="duration"
        :started-at="startedAt"
        :finished-at="finishedAt"
      />

      <ErrorLog
  v-if="errorArtifact"
  :error="errorArtifact.metadata"
/>
        <Artifacts
  v-if="fileArtifacts.length"
  :artifacts="fileArtifacts"
/>
         <RunHistory :runs="testRuns" />
         <Card
  class="bg-[#0d1117] border-l-[3px] border-l-[#6366f1] w-full
         border-r-transparent border-b-transparent border-t-transparent
         rounded-lg"
>
  <CardHeader class="p-4">
    <CardDescription class="text-xs text-[#64748b] leading-5">
      ℹ️ <span class="font-semibold">MVP Note: </span>
      Runs are triggered manually from the Rails UI. Playwright executes
      headless/headed and stores exit codes and artifacts ( Only for the failed runs ) .
    </CardDescription>
  </CardHeader>
</Card>    
    </div>
  </div>
</template>
