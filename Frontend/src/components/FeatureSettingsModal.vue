<script setup>
import { ref, computed, onUnmounted } from 'vue'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { Settings, Play, Loader2 } from 'lucide-vue-next'
import { useTestStore } from '@/stores/testStore'
import { storeToRefs } from 'pinia'
import axios from '@/plugins/axios'

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL

const testStore = useTestStore()
const { tests } = storeToRefs(testStore)

const open = ref(false)
const feature = ref(null)
const testConfigs = ref({})
const savingStatus = ref({}) // track saving state per test

const initConfigs = () => {
  if (!feature.value) return
  const configs = {}
  feature.value.tests.forEach(t => {
    const liveTest = tests.value.find(lt => lt.id === t.id) || t
    configs[t.id] = {
      environment:        liveTest.environment || 'QA',
      tags:               Array.isArray(liveTest.tags) ? [...liveTest.tags] : [],
      retries_on_failure: liveTest.retries_on_failure ?? 2,
      tagInput:           ''
    }
  })
  testConfigs.value = configs
}

const show = async (featureData) => {
  feature.value = featureData
  open.value = true
  // Fetch fresh data first
  await testStore.refreshTestsFromBackend()
  // Init after fresh data
  initConfigs()
}

const close = () => {
  open.value = false
  feature.value = null
  testConfigs.value = {}
  savingStatus.value = {}
}

const onOpenChange = (val) => {
  if (!val) close()
}

onUnmounted(() => close())

// Direct PATCH call — bypasses store saveTestMeta to avoid tag processing issues
async function patchTest(testId, payload) {
  try {
    savingStatus.value[testId] = 'saving'
    await axios.patch(`${API_BASE_URL}/api/tests/${testId}`, payload)
    savingStatus.value[testId] = 'saved'
    setTimeout(() => {
      savingStatus.value[testId] = null
    }, 1500)
  } catch (err) {
    savingStatus.value[testId] = 'error'
    console.error('Failed to save test config:', err)
  }
}

// Save retries immediately on change
async function saveRetries(testId) {
  const config = testConfigs.value[testId]
  if (!config) return

  // Update store instantly
  const index = testStore.tests.findIndex(t => t.id === testId)
  if (index !== -1) {
    testStore.tests[index] = {
      ...testStore.tests[index],
      retries_on_failure: config.retries_on_failure
    }
  }
  if (testStore.selectedTest?.id === testId) {
    testStore.selectedTest.retries_on_failure = config.retries_on_failure
  }

  await patchTest(testId, { retries_on_failure: config.retries_on_failure })
}

// Save tags immediately
async function saveTags(testId) {
  const config = testConfigs.value[testId]
  if (!config) return

  const cleanTags = config.tags
    .map(t => String(t).trim())
    .filter(Boolean)

  // Update store instantly
  testStore.syncTagsToTestsList(testId, cleanTags)

  await patchTest(testId, { tags: cleanTags })
}

// Tags chip logic
function addTag(testId) {
  const config = testConfigs.value[testId]
  if (!config) return
  const val = config.tagInput.trim()
  if (!val) return
  if (config.tags.length >= 10) return
  if (config.tags.includes(val)) {
    config.tagInput = ''
    return
  }
  config.tags = [...config.tags, val]
  config.tagInput = ''
  saveTags(testId)
}

function removeTag(testId, index) {
  const config = testConfigs.value[testId]
  if (!config) return
  config.tags = config.tags.filter((_, i) => i !== index)
  saveTags(testId)
}

function handleTagBackspace(testId) {
  const config = testConfigs.value[testId]
  if (!config) return
  if (config.tagInput === '' && config.tags.length > 0) {
    config.tags = config.tags.slice(0, -1)
    saveTags(testId)
  }
}

// Run all tests in feature
async function runAllTests() {
  if (!feature.value || isFeatureRunning.value) return

  try {
    await testStore.runFeature(feature.value.id, {
      environment: 'QA',
      runner_mode: 'headless',
      retries: 0
    })

    await testStore.refreshTestsFromBackend()
    await testStore.refreshFeaturesFromBackend()
  } catch (err) {
    console.error('Failed to run feature:', err)
  }
}

const liveTests = computed(() => {
  if (!feature.value) return []
  return feature.value.tests.map(t =>
    tests.value.find(lt => lt.id === t.id) || t
  )
})

defineExpose({ show })

const isFeatureRunning = computed(() => {
  if (!feature.value) return false

  return feature.value.tests.some(test => {
    const liveTest = tests.value.find(t => t.id === test.id)

    return ['running', 'queued'].includes(
      liveTest?.status?.toLowerCase()
    )
  })
})
</script>

<template>
  <Dialog v-model:open="open" @update:open="onOpenChange">
    <DialogContent class="w-[95vw] max-w-4xl bg-[#161b26] border-slate-800 text-white overflow-y-auto max-h-[90vh]">
      <DialogHeader>
        <DialogTitle class="text-white flex items-center gap-2">
          <Settings class="w-5 h-5 text-slate-400" />
          Feature Settings — {{ feature?.name }}
        </DialogTitle>
      </DialogHeader>

      <div class="mt-4 space-y-2">

        <!-- Table header (desktop only) -->
        <div class="hidden md:grid grid-cols-4 gap-3 px-4 py-2 text-xs font-semibold uppercase
                    text-slate-400 border-b border-slate-800 bg-[#1c2333] rounded-t-lg">
          <span>Test</span>
          <span>Environment</span>
          <span>Tags</span>
          <span>Retries</span>
        </div>

        <!-- Test rows -->
        <div
          v-for="test in liveTests"
          :key="test.id"
          class="grid grid-cols-1 md:grid-cols-4 gap-3 px-4 py-3 items-start
                 bg-[#1c2333] border-b border-slate-800
                 last:border-none rounded-lg"
        >
          <!-- Test name + status -->
          <div class="flex flex-col gap-1 pt-1">
            <label class="md:hidden block text-xs font-semibold uppercase text-slate-400 mb-1">Test</label>
            <span class="text-white text-sm font-medium break-all leading-tight">
              {{ test.title?.split('_').slice(0, -1).join('_') || test.title }}
            </span>
            <span
              class="text-xs w-fit px-1.5 py-0.5 rounded mt-1"
              :class="{
                'bg-emerald-500/15 text-emerald-400': test.status === 'passed',
                'bg-red-500/15 text-red-400':         test.status === 'failed',
                'bg-amber-500/15 text-amber-400':     test.status === 'running',
                'bg-slate-500/15 text-slate-400':     !['passed','failed','running'].includes(test.status)
              }"
            >
              {{ test.status?.toUpperCase() || 'NEW' }}
            </span>
          </div>

          <!-- Environment -->
          <div v-if="testConfigs[test.id]">
            <label class="md:hidden block text-xs font-semibold uppercase text-slate-400 mb-1">Environment</label>
            <select
              v-model="testConfigs[test.id].environment"
              class="w-full rounded-lg bg-[#0d1117] border border-slate-700
                     px-2 py-1.5 text-sm text-white cursor-pointer"
              @change="patchTest(test.id, { environment: testConfigs[test.id].environment })"
            >
              <option value="QA">QA</option>
              <option value="DEV">DEV</option>
            </select>
          </div>

          <!-- Tags chip input -->
          <div v-if="testConfigs[test.id]">
            <label class="md:hidden block text-xs font-semibold uppercase text-slate-400 mb-1">Tags</label>
            <div
              class="min-h-[36px] w-full rounded-lg bg-[#0d1117] border border-slate-700
                     px-2 py-1 flex flex-wrap gap-1 cursor-text
                     focus-within:border-slate-500 transition-colors"
              @click="$refs['tagInput_' + test.id]?.[0]?.focus()"
            >
              <span
                v-for="(tag, index) in testConfigs[test.id].tags"
                :key="index"
                class="inline-flex items-center gap-0.5 rounded
                       bg-slate-700/40 border border-slate-600/40
                       px-1.5 py-0.5 text-xs text-slate-300"
              >
                <span class="break-all max-w-[120px] md:max-w-[60px]">{{ tag }}</span>
                <button
                  type="button"
                  class="text-slate-400 hover:text-white transition-colors leading-none"
                  @click.stop="removeTag(test.id, index)"
                >×</button>
              </span>

              <input
                v-if="testConfigs[test.id].tags.length < 10"
                :ref="'tagInput_' + test.id"
                v-model="testConfigs[test.id].tagInput"
                type="text"
                placeholder="Add..."
                class="flex-1 min-w-[50px] bg-transparent text-xs text-white
                       placeholder:text-slate-500 outline-none border-none
                       focus:ring-0 py-0.5"
                @keydown.enter.prevent="addTag(test.id)"
                @keydown.backspace="handleTagBackspace(test.id)"
              />
              <span v-else class="text-xs text-slate-500 self-center">Max</span>
            </div>
            <p class="text-xs text-slate-600 mt-0.5">↵ Enter to add</p>
          </div>

          <!-- Retries -->
          <div v-if="testConfigs[test.id]" class="flex flex-col gap-1">
            <label class="md:hidden block text-xs font-semibold uppercase text-slate-400 mb-1">Retries</label>
            <select
              v-model.number="testConfigs[test.id].retries_on_failure"
              class="w-full rounded-lg bg-[#0d1117] border border-slate-700
                     px-2 py-1.5 text-sm text-white cursor-pointer"
              @change="saveRetries(test.id)"
            >
              <option v-for="n in 5" :key="n" :value="n - 1">{{ n - 1 }}</option>
            </select>
            <!-- Save indicator -->
            <span
              v-if="savingStatus[test.id]"
              class="text-xs"
              :class="{
                'text-amber-400':   savingStatus[test.id] === 'saving',
                'text-emerald-400': savingStatus[test.id] === 'saved',
                'text-red-400':     savingStatus[test.id] === 'error'
              }"
            >
              {{ savingStatus[test.id] === 'saving' ? 'Saving…' : savingStatus[test.id] === 'saved' ? 'Saved' : 'Error' }}
            </span>
          </div>
        </div>

        <!-- Empty state -->
        <div v-if="!liveTests.length" class="text-center py-6 text-slate-500 text-sm">
          No tests in this feature yet.
        </div>

        <!-- Run All button -->
        <div class="flex justify-stretch md:justify-end pt-3 border-t border-slate-800">
          <Button
            :disabled="isFeatureRunning"
            class="inline-flex items-center justify-center gap-2 w-full md:w-auto bg-slate-100 hover:bg-white text-slate-900 font-medium
                   disabled:opacity-40 disabled:cursor-not-allowed px-6 focus-visible:ring-2 focus-visible:ring-purple-500 focus-visible:ring-offset-2 focus-visible:ring-offset-slate-900 focus-visible:outline-none"
            @click="runAllTests"
          >
            <template v-if="isFeatureRunning">
              <Loader2 class="w-4 h-4 animate-spin" />
              Running…
            </template>
            <template v-else>
              <Play class="w-4 h-4" />
              Run All Tests
            </template>
          </Button>
        </div>

      </div>
    </DialogContent>
  </Dialog>
</template>