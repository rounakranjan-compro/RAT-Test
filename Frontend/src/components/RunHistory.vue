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
import { History, FlaskConical, AlertTriangle, Image, Video, Search, FileText, Trash2 } from 'lucide-vue-next'
import { useTestStore } from '@/stores/testStore'

const testStore = useTestStore()

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

const handleDeleteTestRun = async (testRunId) => {
  if (!confirm('Delete this test run?')) return
  
  try {
    if (testStore.selectedTest?.id) {
      await testStore.deleteTestRun(testStore.selectedTest.id, testRunId)
      alert('Test run deleted successfully.')
      closeModal()
    }
  } catch (err) {
    console.error('Failed to delete test run:', err)
    alert('Failed to delete test run. Please try again.')
  }
}

const statusClass = (status) => {
  if (status === 'passed') return 'bg-emerald-500/15 text-emerald-400 border border-emerald-500/30'
  if (status === 'failed') return 'bg-red-500/15 text-red-400 border border-red-500/30'
  return 'bg-slate-500/15 text-slate-400 border border-slate-500/30'
}

const artifactIcon = (kind) => {
  if (kind === 'screenshot') return Image
  if (kind === 'video') return Video
  if (kind === 'trace') return Search
  return FileText
}
</script>

<template>
  <div>
    <Card class="border-slate-800 bg-[#1c2333]">
      <CardHeader class="flex flex-row items-center justify-between">
        <CardTitle class="flex items-center gap-2 text-white">
          <History class="w-5 h-5 text-slate-400" />
          Run History
        </CardTitle>

      </CardHeader>

      <CardContent class="p-0">
        <div
          class="hidden md:grid grid-cols-5 px-6 py-3
                 text-xs font-semibold uppercase
                 text-slate-400
                 border-b border-slate-800 bg-[#1c2333]"
        >
          <span>Run ID</span>
          <span>Status</span>
          <span>Environment</span>
          <span>Duration</span>
          <span class="text-right">Action</span>
        </div>

        <div
          v-for="run in runs"
          :key="run.id"
          class="border-b border-slate-800 last:border-none"
        >
          <!-- Desktop -->
          <div
            class="hidden md:grid grid-cols-5 px-6 py-4
                   items-center
                   hover:bg-[#161b26]/40 transition cursor-pointer"
            @click="openModal(run)"
          >
            <span class="font-medium text-white">{{ run.id }}</span>
            <Badge :class="statusClass(run.status)" class="w-fit">
              {{ run.status.toUpperCase() }}
            </Badge>
            <span class="text-slate-200">{{ run.environment }}</span>
            <span class="text-slate-200">{{ run.duration }}</span>
            <div class="flex justify-end">
              <Button
                size="sm"
                variant="ghost"
                class="h-8 px-3 text-xs text-slate-400 hover:text-white hover:bg-[#2a3347]"
                @click.stop="handleDeleteTestRun(run.id)"
                title="Delete if test run appears stuck - retry again"
              >
                <Trash2 class="w-3 h-3 mr-1" />
                Delete
              </Button>
            </div>
          </div>

          <!-- Mobile -->
          <div class="md:hidden px-4 py-4 space-y-2" @click="openModal(run)">
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
            <div class="flex justify-end pt-2">
              <Button
                size="sm"
                variant="ghost"
                class="h-8 px-3 text-xs text-slate-400 hover:text-white hover:bg-[#2a3347]"
                @click.stop="handleDeleteTestRun(run.id)"
                title="Delete if test run appears stuck - retry again"
              >
                <Trash2 class="w-3 h-3 mr-1" />
                Delete
              </Button>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>

    <!-- Run Detail Modal -->
    <Dialog v-model:open="modalOpen">
  <DialogContent class="w-[95vw] max-w-lg bg-[#161b26] border-slate-800 text-white overflow-y-auto max-h-[90vh]">
    <DialogHeader>
      <DialogTitle class="text-white flex items-center gap-2 flex-wrap">
        <FlaskConical class="w-5 h-5 text-slate-400" />
        Run Details
        <Badge v-if="selectedRun" :class="statusClass(selectedRun.status)" class="ml-2">
          {{ selectedRun?.status?.toUpperCase() }}
        </Badge>
      </DialogTitle>
    </DialogHeader>

    <div v-if="selectedRun" class="space-y-4 mt-2">

      <!-- Basic Info -->
      <div class="grid grid-cols-2 gap-2">
        <div class="bg-[#1c2333] rounded-lg p-3">
          <p class="text-xs text-slate-400 mb-1">Run ID</p>
          <p class="text-white font-medium">{{ selectedRun.id }}</p>
        </div>
        <div class="bg-[#1c2333] rounded-lg p-3">
          <p class="text-xs text-slate-400 mb-1">Environment</p>
          <p class="text-white font-medium">{{ selectedRun.environment }}</p>
        </div>
        <div class="bg-[#1c2333] rounded-lg p-3">
          <p class="text-xs text-slate-400 mb-1">Runner Mode</p>
          <p class="text-white font-medium capitalize">{{ selectedRun.runner_mode }}</p>
        </div>
        <div class="bg-[#1c2333] rounded-lg p-3">
          <p class="text-xs text-slate-400 mb-1">Duration</p>
          <p class="text-white font-medium">{{ selectedRun.duration }}</p>
        </div>
        <div class="bg-[#1c2333] rounded-lg p-3">
          <p class="text-xs text-slate-400 mb-1">Retries</p>
          <p class="text-white font-medium">{{ selectedRun.retries_on_failure }}</p>
        </div>
        <div class="bg-[#1c2333] rounded-lg p-3">
          <p class="text-xs text-slate-400 mb-1">Started At</p>
          <p class="text-white font-medium text-xs">
            {{ selectedRun.started_at ? new Date(selectedRun.started_at).toLocaleString() : 'N/A' }}
          </p>
        </div>
        <div class="bg-[#1c2333] rounded-lg p-3 col-span-2">
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
            class="flex items-center justify-between bg-[#1c2333] rounded-lg px-3 py-2"
          >
            <span class="flex items-center gap-2 text-sm text-slate-300 capitalize">
              <component :is="artifactIcon(artifact.kind)" class="w-4 h-4 text-slate-400" />
              {{ artifact.kind }}
            </span>
            <a
              v-if="artifact.file_url"
              :href="artifact.file_url"
              target="_blank"
              class="text-xs text-slate-300 hover:text-white hover:underline"
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
        class="bg-[#1c2333] rounded-lg p-3 text-center"
      >
        <p class="text-xs text-slate-400">No artifacts available for this run</p>
      </div>

      <!-- Error Log -->
      <div
        v-if="selectedRun.artifacts?.find(a => a.kind === 'error_log')"
        class="bg-red-500/10 border border-red-500/30 rounded-lg p-3"
      >
        <p class="flex items-center gap-1.5 text-xs text-red-400 uppercase font-semibold mb-2">
          <AlertTriangle class="w-3.5 h-3.5" />
          Error Log
        </p>
        <pre class="text-xs text-red-300 whitespace-pre-wrap overflow-auto max-h-32 break-all">{{
          selectedRun.artifacts.find(a => a.kind === 'error_log')?.metadata
        }}</pre>
      </div>

      <!-- Delete Button -->
      <div class="flex justify-end pt-3 border-t border-slate-800">
        <Button
          size="sm"
          variant="ghost"
          class="h-8 px-3 text-xs text-slate-400 hover:text-white hover:bg-[#2a3347]"
          @click="handleDeleteTestRun(selectedRun.id)"
          title="Delete if test run appears stuck - retry again"
        >
          <Trash2 class="w-3 h-3 mr-1" />
          Delete
        </Button>
      </div>

    </div>
  </DialogContent>
</Dialog>
  </div>
</template>