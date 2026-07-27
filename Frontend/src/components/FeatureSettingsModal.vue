<script setup>
import { ref, computed, onUnmounted } from 'vue'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
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

// ---- new: search / sort state ----
const searchQuery = ref('')
const sortFailedFirst = ref(false)

// ---- new: bulk-apply state ----
const bulkEnvironment = ref('QA')
const bulkRetries = ref(2)

const DEFAULT_ENV = 'QA'
const DEFAULT_RETRIES = 2
const MAX_TAG_LENGTH = 30

const initConfigs = () => {
  if (!feature.value) return
  const configs = {}
  feature.value.tests.forEach(t => {
    const liveTest = tests.value.find(lt => lt.id === t.id) || t
    configs[t.id] = {
      environment:        liveTest.environment || DEFAULT_ENV,
      tags:               Array.isArray(liveTest.tags) ? [...liveTest.tags] : [],
      retries_on_failure: liveTest.retries_on_failure ?? DEFAULT_RETRIES,
      tagInput:           ''
    }
  })
  testConfigs.value = configs
}

const show = async (featureData) => {
  feature.value = featureData
  open.value = true
  searchQuery.value = ''
  sortFailedFirst.value = false
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
  searchQuery.value = ''
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
  const val = config.tagInput.trim().slice(0, MAX_TAG_LENGTH)
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

// ---- new: copy one test's tags onto every other test in the feature ----
function copyTagsToAll(sourceTestId) {
  const source = testConfigs.value[sourceTestId]
  if (!source) return
  Object.keys(testConfigs.value).forEach(testId => {
    if (testId === String(sourceTestId)) return
    testConfigs.value[testId].tags = [...source.tags]
    saveTags(testId)
  })
}

// ---- new: reset a single test's config back to defaults ----
function resetTestConfig(testId) {
  const config = testConfigs.value[testId]
  if (!config) return
  config.environment = DEFAULT_ENV
  config.retries_on_failure = DEFAULT_RETRIES
  config.tags = []
  config.tagInput = ''
  patchTest(testId, {
    environment: DEFAULT_ENV,
    retries_on_failure: DEFAULT_RETRIES,
    tags: []
  })
}

// ---- new: bulk apply environment/retries across every test ----
async function applyEnvironmentToAll() {
  const ids = Object.keys(testConfigs.value)
  for (const testId of ids) {
    testConfigs.value[testId].environment = bulkEnvironment.value
    await patchTest(testId, { environment: bulkEnvironment.value })
  }
}

async function applyRetriesToAll() {
  const ids = Object.keys(testConfigs.value)
  for (const testId of ids) {
    testConfigs.value[testId].retries_on_failure = bulkRetries.value
    await saveRetries(testId)
  }
}

// Run all tests in feature
const isRunning = ref(false)
async function runAllTests() {
  if (!feature.value) return
  isRunning.value = true
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
  } finally {
    isRunning.value = false
  }
}

// ---- new: run only the currently failed tests in this feature ----
const isRunningFailed = ref(false)
async function runFailedTests() {
  if (!feature.value) return
  const failedIds = liveTests.value
    .filter(t => t.status === 'failed')
    .map(t => t.id)
  if (!failedIds.length) return

  isRunningFailed.value = true
  try {
    // Assumes runFeature can be scoped to specific tests via test_ids.
    // Falls back to a full feature run if the store method ignores the option.
    await testStore.runFeature(feature.value.id, {
      environment: 'QA',
      runner_mode: 'headless',
      retries: 0,
      test_ids: failedIds
    })
    await testStore.refreshTestsFromBackend()
    await testStore.refreshFeaturesFromBackend()
  } catch (err) {
    console.error('Failed to run failed tests:', err)
  } finally {
    isRunningFailed.value = false
  }
}

const liveTests = computed(() => {
  if (!feature.value) return []
  return feature.value.tests.map(t =>
    tests.value.find(lt => lt.id === t.id) || t
  )
})

// ---- new: search + sort applied on top of liveTests ----
const displayedTests = computed(() => {
  let result = liveTests.value

  if (searchQuery.value.trim()) {
    const q = searchQuery.value.trim().toLowerCase()
    result = result.filter(t =>
      (t.title || '').toLowerCase().includes(q) ||
      (testConfigs.value[t.id]?.tags || []).some(tag => tag.toLowerCase().includes(q))
    )
  }

  if (sortFailedFirst.value) {
    const rank = { failed: 0, running: 1, passed: 2 }
    result = [...result].sort((a, b) => {
      const ra = rank[a.status] ?? 3
      const rb = rank[b.status] ?? 3
      return ra - rb
    })
  }

  return result
})

// ---- new: quick status summary for the header ----
const statusCounts = computed(() => {
  const counts = { passed: 0, failed: 0, running: 0, other: 0 }
  liveTests.value.forEach(t => {
    if (counts[t.status] !== undefined) counts[t.status]++
    else counts.other++
  })
  return counts
})

const hasFailedTests = computed(() => statusCounts.value.failed > 0)

defineExpose({ show })
</script>

<template>
  <Dialog v-model:open="open" @update:open="onOpenChange">
    <DialogContent class="w-[95vw] max-w-4xl bg-slate-900 border-slate-700 text-white overflow-y-auto max-h-[90vh]">
      <DialogHeader>
        <DialogTitle class="text-white flex items-center gap-2">
          ⚙️ Feature Settings — {{ feature?.name }}
        </DialogTitle>
      </DialogHeader>

      <!-- Status summary -->
      <div class="flex items-center gap-3 text-xs text-slate-400 mt-2">
        <span class="text-emerald-400">{{ statusCounts.passed }} passed</span>
        <span class="text-red-400">{{ statusCounts.failed }} failed</span>
        <span class="text-yellow-400">{{ statusCounts.running }} running</span>
        <span class="text-slate-500">{{ statusCounts.other }} new</span>
      </div>

      <!-- Toolbar: search, sort, bulk apply -->
      <div class="mt-3 flex flex-wrap items-center gap-2 bg-slate-800/60 border border-slate-700 rounded-lg p-2">
        <input
          v-model="searchQuery"
          type="text"
          placeholder="Search tests or tags..."
          class="flex-1 min-w-[160px] rounded-lg bg-slate-700 border border-slate-600
                 px-2 py-1.5 text-sm text-white placeholder:text-slate-500 outline-none"
        />

        <button
          type="button"
          class="text-xs px-2 py-1.5 rounded-lg border transition-colors"
          :class="sortFailedFirst
            ? 'bg-indigo-600/30 border-indigo-500/40 text-indigo-200'
            : 'bg-slate-700 border-slate-600 text-slate-300'"
          @click="sortFailedFirst = !sortFailedFirst"
        >
          Failed first
        </button>

        <div class="flex items-center gap-1">
          <select
            v-model="bulkEnvironment"
            class="rounded-lg bg-slate-700 border border-slate-600 px-2 py-1.5 text-xs text-white cursor-pointer"
          >
            <option value="QA">QA</option>
            <option value="DEV">DEV</option>
          </select>
          <button
            type="button"
            class="text-xs px-2 py-1.5 rounded-lg bg-slate-700 border border-slate-600 text-slate-300 hover:text-white"
            @click="applyEnvironmentToAll"
          >
            Apply env to all
          </button>
        </div>

        <div class="flex items-center gap-1">
          <select
            v-model.number="bulkRetries"
            class="rounded-lg bg-slate-700 border border-slate-600 px-2 py-1.5 text-xs text-white cursor-pointer"
          >
            <option v-for="n in 5" :key="n" :value="n - 1">{{ n - 1 }} retries</option>
          </select>
          <button
            type="button"
            class="text-xs px-2 py-1.5 rounded-lg bg-slate-700 border border-slate-600 text-slate-300 hover:text-white"
            @click="applyRetriesToAll"
          >
            Apply to all
          </button>
        </div>
      </div>

      <div class="mt-4 space-y-2">

        <!-- Table header -->
        <div class="grid grid-cols-5 gap-3 px-4 py-2 text-xs font-semibold uppercase
                    text-slate-400 border-b border-slate-700 bg-slate-800 rounded-t-lg">
          <span>Test</span>
          <span>Environment</span>
          <span>Tags</span>
          <span>Retries</span>
          <span>Actions</span>
        </div>

        <!-- Test rows -->
        <div
          v-for="test in displayedTests"
          :key="test.id"
          class="grid grid-cols-5 gap-3 px-4 py-3 items-start
                 bg-slate-800 border-b border-slate-700
                 last:border-none rounded-lg"
        >
          <!-- Test name + status -->
          <div class="flex flex-col gap-1 pt-1">
            <span class="text-white text-sm font-medium break-all leading-tight">
              {{ test.title?.split('_').slice(0, -1).join('_') || test.title }}
            </span>
            <span
              class="text-xs w-fit px-1.5 py-0.5 rounded mt-1"
              :class="{
                'bg-emerald-600/20 text-emerald-400': test.status === 'passed',
                'bg-red-600/20 text-red-400':         test.status === 'failed',
                'bg-yellow-600/20 text-yellow-400':   test.status === 'running',
                'bg-slate-600/20 text-slate-400':     !['passed','failed','running'].includes(test.status)
              }"
            >
              {{ test.status?.toUpperCase() || 'NEW' }}
            </span>
          </div>

          <!-- Environment -->
          <div v-if="testConfigs[test.id]">
            <select
              v-model="testConfigs[test.id].environment"
              class="w-full rounded-lg bg-slate-700 border border-slate-600
                     px-2 py-1.5 text-sm text-white cursor-pointer"
              @change="patchTest(test.id, { environment: testConfigs[test.id].environment })"
            >
              <option value="QA">QA</option>
              <option value="DEV">DEV</option>
            </select>
          </div>

          <!-- Tags chip input -->
          <div v-if="testConfigs[test.id]">
            <div
              class="min-h-[36px] w-full rounded-lg bg-slate-700 border border-slate-600
                     px-2 py-1 flex flex-wrap gap-1 cursor-text
                     focus-within:border-indigo-500 transition-colors"
              @click="$refs['tagInput_' + test.id]?.[0]?.focus()"
            >
              <span
                v-for="(tag, index) in testConfigs[test.id].tags"
                :key="index"
                class="inline-flex items-center gap-0.5 rounded
                       bg-indigo-600/30 border border-indigo-500/40
                       px-1.5 py-0.5 text-xs text-indigo-200"
              >
                <span class="break-all max-w-[60px]">{{ tag }}</span>
                <button
                  type="button"
                  class="text-indigo-300 hover:text-white transition-colors leading-none"
                  @click.stop="removeTag(test.id, index)"
                >×</button>
              </span>

              <input
                v-if="testConfigs[test.id].tags.length < 10"
                :ref="'tagInput_' + test.id"
                v-model="testConfigs[test.id].tagInput"
                type="text"
                placeholder="Add..."
                maxlength="30"
                class="flex-1 min-w-[50px] bg-transparent text-xs text-white
                       placeholder:text-slate-500 outline-none border-none
                       focus:ring-0 py-0.5"
                @keydown.enter.prevent="addTag(test.id)"
                @keydown.backspace="handleTagBackspace(test.id)"
              />
              <span v-else class="text-xs text-slate-500 self-center">Max</span>
            </div>
            <div class="flex items-center justify-between mt-0.5">
              <p class="text-xs text-slate-600">↵ Enter to add</p>
              <button
                v-if="testConfigs[test.id].tags.length"
                type="button"
                class="text-xs text-slate-500 hover:text-indigo-300"
                @click="copyTagsToAll(test.id)"
              >
                Copy to all
              </button>
            </div>
          </div>

          <!-- Retries -->
          <div v-if="testConfigs[test.id]" class="flex flex-col gap-1">
            <select
              v-model.number="testConfigs[test.id].retries_on_failure"
              class="w-full rounded-lg bg-slate-700 border border-slate-600
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
                'text-yellow-400': savingStatus[test.id] === 'saving',
                'text-green-400':  savingStatus[test.id] === 'saved',
                'text-red-400':    savingStatus[test.id] === 'error'
              }"
            >
              {{ savingStatus[test.id] === 'saving' ? 'Saving...' : savingStatus[test.id] === 'saved' ? '✓ Saved' : '✗ Error' }}
            </span>
          </div>

          <!-- Actions -->
          <div v-if="testConfigs[test.id]" class="pt-1">
            <button
              type="button"
              class="text-xs px-2 py-1 rounded-lg bg-slate-700 border border-slate-600
                     text-slate-300 hover:text-white hover:border-slate-500"
              @click="resetTestConfig(test.id)"
            >
              Reset
            </button>
          </div>
        </div>

        <!-- Empty state -->
        <div v-if="!displayedTests.length && liveTests.length" class="text-center py-6 text-slate-500 text-sm">
          No tests match "{{ searchQuery }}".
        </div>
        <div v-else-if="!liveTests.length" class="text-center py-6 text-slate-500 text-sm">
          No tests in this feature yet.
        </div>

        <!-- Run actions -->
        <div class="flex justify-end gap-2 pt-3 border-t border-slate-700">
          <Button
            v-if="hasFailedTests"
            :disabled="isRunningFailed"
            variant="outline"
            class="border-red-500/40 text-red-300 hover:bg-red-600/10
                   disabled:opacity-40 disabled:cursor-not-allowed px-4"
            @click="runFailedTests"
          >
            <span v-if="isRunningFailed" class="animate-pulse">⏳ Running...</span>
            <span v-else>↻ Run Failed Only ({{ statusCounts.failed }})</span>
          </Button>

          <Button
            :disabled="isRunning"
            class="bg-green-600 hover:bg-green-700 text-white
                   disabled:opacity-40 disabled:cursor-not-allowed px-6"
            @click="runAllTests"
          >
            <span v-if="isRunning" class="animate-pulse">⏳ Running...</span>
            <span v-else>▶ Run All Tests</span>
          </Button>
        </div>

      </div>
    </DialogContent>
  </Dialog>
</template>