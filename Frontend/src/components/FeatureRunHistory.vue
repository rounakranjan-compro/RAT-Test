<script setup>
import { ref, onUnmounted } from 'vue'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { Badge } from "@/components/ui/badge"
import { useTestStore } from '@/stores/testStore'

const testStore = useTestStore()
const open = ref(false)
const feature = ref(null)
const pollingInterval = ref(null)

const startPolling = () => {
  pollingInterval.value = setInterval(async () => {
    await testStore.refreshFeaturesFromBackend()
    // sync feature data with updated features
    const updated = testStore.features.find(f => f.id === feature.value?.id)
    if (updated) feature.value = updated
  }, 3000)
}

const stopPolling = () => {
  if (pollingInterval.value) {
    clearInterval(pollingInterval.value)
    pollingInterval.value = null
  }
}

const show = (featureData) => {
  feature.value = featureData
  open.value = true
  startPolling()
}

const close = () => {
  open.value = false
  feature.value = null
  stopPolling()
}

// stop polling if dialog closed via outside click
const onOpenChange = (val) => {
  if (!val) close()
}

onUnmounted(() => stopPolling())

const statusClass = (status) => {
  if (status === 'passed') return 'bg-emerald-600'
  if (status === 'failed') return 'bg-red-600'
  if (status === 'running') return 'bg-yellow-600'
  if (status === 'queued') return 'bg-blue-600'
  return 'bg-slate-600'
}

defineExpose({ show })
</script>

<template>
  <Dialog v-model:open="open" @update:open="onOpenChange">
    <DialogContent class="w-[95vw] max-w-2xl bg-slate-900 border-slate-700 text-white overflow-y-auto max-h-[90vh]">
      <DialogHeader>
        <DialogTitle class="text-white flex items-center gap-2">
          📊 Last Run — {{ feature?.name }}
        </DialogTitle>
      </DialogHeader>

      <div class="space-y-3 mt-2">
        <!-- Table header -->
        <div class="hidden md:grid grid-cols-4 px-4 py-2 text-xs font-semibold uppercase text-slate-400 border-b border-slate-700 bg-slate-800 rounded-t-lg">
          <span>Test</span>
          <span>Status</span>
          <span>Last Run</span>
          <span class="text-right">Duration</span>
        </div>

        <!-- Test rows -->
        <div
          v-for="test in feature?.tests"
          :key="test.id"
          class="border-b border-slate-700 last:border-none"
        >
          <!-- Desktop -->
          <div class="hidden md:grid grid-cols-4 px-4 py-3 items-center bg-slate-800 hover:bg-slate-700/50 transition">
            <span class="text-white text-sm truncate">{{ test.title?.split('_').slice(0, -1).join('_') || test.title }}</span>
            <Badge :class="statusClass(test.status)" class="w-fit text-xs">
              {{ test.status?.toUpperCase() || 'NEW' }}
            </Badge>
            <span class="text-slate-300 text-xs">
              {{ test.lastRun ? new Date(test.lastRun).toLocaleString() : 'Never' }}
            </span>
            <span class="text-right text-slate-300 text-sm">
              {{ test.duration || '—' }}
            </span>
          </div>

          <!-- Mobile -->
          <div class="md:hidden px-4 py-3 space-y-1 bg-slate-800">
            <div class="flex items-center justify-between">
              <span class="text-white text-sm font-medium truncate">{{ test.title }}</span>
              <Badge :class="statusClass(test.status)" class="text-xs ml-2">
                {{ test.status?.toUpperCase() || 'NEW' }}
              </Badge>
            </div>
            <div class="flex justify-between text-xs text-slate-400">
              <span>{{ test.lastRun ? new Date(test.lastRun).toLocaleString() : 'Never run' }}</span>
              <span>{{ test.duration || '—' }}</span>
            </div>
          </div>
        </div>

        <!-- Empty state -->
        <div v-if="!feature?.tests?.length" class="text-center py-6 text-slate-500 text-sm">
          No tests in this feature yet.
        </div>
      </div>
    </DialogContent>
  </Dialog>
</template>