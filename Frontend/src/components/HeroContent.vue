<script setup>
import { computed, watch } from 'vue'
import { useTestStore } from '@/stores/testStore'
import { storeToRefs } from 'pinia'
import { useTestOperations } from '@/composables/useTestOperations'

import HeadingBar from '@/components/HeadingBar.vue'
import TestData from '@/components/TestData.vue'
import ScriptViewer from '@/components/ScriptViewer.vue'
import RunResult from '@/components/RunResult.vue'

const testStore = useTestStore()
const { selectedTest, testRuns } = storeToRefs(testStore)

const { runSelectedTest } = useTestOperations()

watch(
  () => selectedTest.value?.id,
  async (newId) => {
    if (newId) await testStore.fetchTestRuns(newId)
  },
  { immediate: true }
)

const environment = computed({
  get: () => selectedTest.value?.environment || 'QA',
  set: val => {
    if (!selectedTest.value) return
    selectedTest.value.environment = val
    testStore.saveTestMeta(selectedTest.value.id, { environment: val })  // ← save to DB
  }
})

// Called from HeadingBar × button
function removeTagFromHeading(index) {
  if (!selectedTest.value) return
  const newTags = selectedTest.value.tags.filter((_, i) => i !== index)
  testStore.syncTagsToTestsList(selectedTest.value.id, newTags)
  testStore.saveTestMeta(selectedTest.value.id, { tags: newTags })
}

// Called from TestData Enter key
function handleTagsUpdate(newTags) {
  if (!selectedTest.value) return
  // Updates BOTH selectedTest and tests array instantly
  testStore.syncTagsToTestsList(selectedTest.value.id, newTags)
  testStore.saveTestMeta(selectedTest.value.id, { tags: newTags })
}


const tags = computed({
  get: () => {
    const t = selectedTest.value?.tags
    if (!t) return []
    if (Array.isArray(t)) return t
    return t.split(',').map(s => s.trim()).filter(Boolean)
  },
  set: val => handleTagsUpdate(Array.isArray(val) ? val : [])
})

const runnerMode = computed({
  get: () => selectedTest.value?.runner_mode || 'headless',
  set: val => {
    selectedTest.value.runner_mode = val
    if (selectedTest.value?.id) {
      testStore.saveTestMeta(selectedTest.value.id, { runner_mode: val })
    }
  }
})

const retries = computed({
  get: () => selectedTest.value?.retries_on_failure ?? 2,
  set: val => {
    selectedTest.value.retries_on_failure = val
    if (selectedTest.value?.id) {
      testStore.saveTestMeta(selectedTest.value.id, { retries_on_failure: val })
    }
  }
})

const rawScriptContent = computed(() => selectedTest.value?.script?.raw || '// No script available')
const normalizedScriptContent = computed(() => selectedTest.value?.script?.normalized || '// No script available')
const scriptFilename = computed(() => selectedTest.value?.script_filename || `${selectedTest.value?.title}.spec.js`)
</script>

<template>
  <div class="w-full mt-5 lg:mt-0 lg:ml-10 lg:w-[75%] rounded-xl space-y-6 bg-[#161b26]">
    <HeadingBar
      v-if="selectedTest"
      :title="selectedTest.title"
      :tags="tags"
      :environment="selectedTest.environment"
      @removeTag="removeTagFromHeading"
    />

    <TestData
      v-if="selectedTest"
      :environment="environment"
      :tags="tags"
      :runnerMode="runnerMode"
      :retries="retries"
      :environments="[
        { value: 'QA', label: 'QA' },
        { value: 'DEV', label: 'DEV' }
      ]"
      @update:environment="environment = $event"
      @update:tags="handleTagsUpdate($event)"
      @update:runnerMode="runnerMode = $event"
      @update:retries="retries = $event"
    />

    <ScriptViewer
      v-if="selectedTest"
      :rawScript="rawScriptContent"
      :normalizedScript="normalizedScriptContent"
      :scriptFilename="scriptFilename"
    />

    <RunResult
      v-if="selectedTest"
      :runs="testRuns"
    />
  </div>
</template>