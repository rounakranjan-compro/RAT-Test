<script setup>
import { ref } from 'vue'
import {
  Card,
  CardHeader,
  CardTitle,
  CardContent,
} from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"

const props = defineProps({
  runs: {
    type: Array,
    required: true,
  },
})

const selectedRun = ref(null)
const modalOpen = ref(false)

const openModal = (run) => {
  selectedRun.value = run
  modalOpen.value = true
}

const closeModal = () => {
  modalOpen.value = false
  selectedRun.value = null
}

const statusClass = (status) => {
  if (status === 'passed') return 'bg-emerald-600'
  if (status === 'failed') return 'bg-red-600'
  return 'bg-slate-600'
}

const artifactIcon = (kind) => {
  if (kind === 'screenshot') return '🖼️'
  if (kind === 'video') return '🎥'
  if (kind === 'trace') return '🔍'
  if (kind === 'error_log') return '❌'
  return '📄'
}
</script>

<template>
  <div>
    <Card class="border-slate-800 bg-gradient-to-b from-slate-900 to-slate-950">
      <CardHeader class="flex flex-row items-center justify-between">
        <CardTitle class="flex items-center gap-2 text-white">
          📅 Run History
        </CardTitle>

      </CardHeader>

      <CardContent class="p-0">
        <div
          class="hidden md:grid grid-cols-4 px-6 py-3
                 text-xs font-semibold uppercase
                 text-slate-400
                 border-b border-slate-800 bg-[#1c2333]"
        >
          <span>Run ID</span>
          <span>Status</span>
          <span>Environment</span>
          <span class="text-right">Duration</span>
        </div>

        <div
          v-for="run in runs"
          :key="run.id"
          class="border-b border-slate-800 last:border-none cursor-pointer"
          @click="openModal(run)"
        >
          <!-- Desktop -->
          <div
            class="hidden md:grid grid-cols-4 px-6 py-4
                   items-center
                   hover:bg-slate-900/40 transition"
          >
            <span class="font-medium text-white">{{ run.id }}</span>
            <Badge :class="statusClass(run.status)" class="w-fit">
              {{ run.status.toUpperCase() }}
            </Badge>
            <span class="text-slate-200">{{ run.environment }}</span>
            <span class="text-right text-slate-200">{{ run.duration }}</span>
          </div>

          <!-- Mobile -->
          <div class="md:hidden px-4 py-4 space-y-2">
            <div class="flex items-center justify-between">
              <span class="font-medium text-white">{{ run.id }}</span>
              <Badge :class="statusClass(run.status)">
                {{ run.status.toUpperCase() }}
              </Badge>
            </div>
            <div class="flex justify-between text-sm text-slate-300">
              <span>Environment</span>
              <span>{{ run.environment }}</span>
            </div>
            <div class="flex justify-between text-sm text-slate-300">
              <span>Duration</span>
              <span>{{ run.duration }}</span>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>

    <!-- Run Detail Modal -->
    <Dialog v-model:open="modalOpen">
  <DialogContent class="w-[95vw] max-w-lg bg-slate-900 border-slate-700 text-white overflow-y-auto max-h-[90vh]">
    <DialogHeader>
      <DialogTitle class="text-white flex items-center gap-2 flex-wrap">
        🧪 Run Details
        <Badge v-if="selectedRun" :class="statusClass(selectedRun.status)" class="ml-2">
          {{ selectedRun?.status?.toUpperCase() }}
        </Badge>
      </DialogTitle>
    </DialogHeader>

    <div v-if="selectedRun" class="space-y-4 mt-2">

      <!-- Basic Info -->
      <div class="grid grid-cols-2 gap-2">
        <div class="bg-slate-800 rounded-lg p-3">
          <p class="text-xs text-slate-400 mb-1">Run ID</p>
          <p class="text-white font-medium">{{ selectedRun.id }}</p>
        </div>
        <div class="bg-slate-800 rounded-lg p-3">
          <p class="text-xs text-slate-400 mb-1">Environment</p>
          <p class="text-white font-medium">{{ selectedRun.environment }}</p>
        </div>
        <div class="bg-slate-800 rounded-lg p-3">
          <p class="text-xs text-slate-400 mb-1">Runner Mode</p>
          <p class="text-white font-medium capitalize">{{ selectedRun.runner_mode }}</p>
        </div>
        <div class="bg-slate-800 rounded-lg p-3">
          <p class="text-xs text-slate-400 mb-1">Duration</p>
          <p class="text-white font-medium">{{ selectedRun.duration }}</p>
        </div>
        <div class="bg-slate-800 rounded-lg p-3">
          <p class="text-xs text-slate-400 mb-1">Retries</p>
          <p class="text-white font-medium">{{ selectedRun.retries_on_failure }}</p>
        </div>
        <div class="bg-slate-800 rounded-lg p-3">
          <p class="text-xs text-slate-400 mb-1">Started At</p>
          <p class="text-white font-medium text-xs">
            {{ selectedRun.started_at ? new Date(selectedRun.started_at).toLocaleString() : 'N/A' }}
          </p>
        </div>
        <div class="bg-slate-800 rounded-lg p-3 col-span-2">
          <p class="text-xs text-slate-400 mb-1">Finished At</p>
          <p class="text-white font-medium text-xs">
            {{ selectedRun.finished_at ? new Date(selectedRun.finished_at).toLocaleString() : 'Still running...' }}
          </p>
        </div>
      </div>

      <!-- Artifacts -->
      <div v-if="selectedRun.artifacts?.filter(a => a.kind !== 'error_log').length > 0">
        <p class="text-xs text-slate-400 uppercase font-semibold mb-2">Artifacts</p>
        <div class="space-y-2">
          <div
            v-for="artifact in selectedRun.artifacts.filter(a => a.kind !== 'error_log')"
            :key="artifact.kind"
            class="flex items-center justify-between bg-slate-800 rounded-lg px-3 py-2"
          >
            <span class="text-sm text-slate-300 capitalize">
              {{ artifactIcon(artifact.kind) }} {{ artifact.kind }}
            </span>
            <a
              v-if="artifact.file_url"
              :href="artifact.file_url"
              target="_blank"
              class="text-xs text-blue-400 hover:underline"
            >
              View →
            </a>
            <span v-else class="text-xs text-slate-500">No file</span>
          </div>
        </div>
      </div>

      <!-- No artifacts message -->
      <div
        v-else-if="!selectedRun.artifacts || selectedRun.artifacts.filter(a => a.kind !== 'error_log').length === 0"
        class="bg-slate-800 rounded-lg p-3 text-center"
      >
        <p class="text-xs text-slate-400">No artifacts available for this run</p>
      </div>

      <!-- Error Log -->
      <div
        v-if="selectedRun.artifacts?.find(a => a.kind === 'error_log')"
        class="bg-red-950/40 border border-red-800 rounded-lg p-3"
      >
        <p class="text-xs text-red-400 uppercase font-semibold mb-2">❌ Error Log</p>
        <pre class="text-xs text-red-300 whitespace-pre-wrap overflow-auto max-h-32 break-all">{{
          selectedRun.artifacts.find(a => a.kind === 'error_log')?.metadata
        }}</pre>
      </div>

    </div>
  </DialogContent>
</Dialog>
  </div>
</template>