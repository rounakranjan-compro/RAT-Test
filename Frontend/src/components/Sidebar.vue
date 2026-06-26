<script setup>
import {
  Card, CardContent, CardDescription,
  CardFooter, CardHeader, CardTitle
} from '@/components/ui/card'
import Separator from './ui/separator/Separator.vue'
import PassFailCountCard from './PassFailCountCard.vue'
import TestCard from './TestCard.vue'
import InformationalTip from './InformationalTip.vue'
import FeatureRunHistory from './FeatureRunHistory.vue'
import { onMounted, ref, computed } from 'vue'
import { useTestStore } from '@/stores/testStore'
import { storeToRefs } from 'pinia'
import { useTestFilter } from '@/composables/useTestFilter'
import { useTestStats } from '@/composables/useTestStats'
import { useTestOperations } from '@/composables/useTestOperations'
import ScrollArea from './ui/scroll-area/ScrollArea.vue'
import { ChevronDown, ChevronRight, Play, Trash2, History, Settings } from 'lucide-vue-next'
import Button from './ui/button/Button.vue'
import FeatureSettingsModal from './FeatureSettingsModal.vue'
import StatusBadge from '@/components/StatusBadge.vue'

const featureSettingsRef = ref(null)
const testStore = useTestStore()
const { tests, features, selectedTest, searchQuery } = storeToRefs(testStore)
const { runSelectedTest } = useTestOperations()

const expandedFeatures = ref(new Set())
const featureHistoryRef = ref(null)

const totalTestCount = computed(() => {
  const featureTestIds = new Set(features.value.flatMap(f => f.tests.map(t => t.id)))
  const standaloneCount = tests.value.filter(t => !featureTestIds.has(t.id)).length
  return standaloneCount + features.value.reduce((a, f) => a + f.tests.length, 0)
})

const visibleTestCount = computed(() => {
  return getStandaloneTests().length + filteredFeatures.value.reduce((a, f) => a + f.tests.length, 0)
})

onMounted(async () => {
  await Promise.all([
    testStore.refreshTestsFromBackend(),
    testStore.refreshFeaturesFromBackend()
  ])
  if (tests.value.length > 0) testStore.setSelectedTest(tests.value[0])
})

const handleOpenSettings = (feature) => featureSettingsRef.value?.show(feature)

const { filteredTests, filteredFeatures } = useTestFilter(tests, searchQuery, features)
const { passCnt, failCnt, runCnt, queueCnt } = useTestStats(tests)

const handleRunTest = async (test) => {
  testStore.setSelectedTest(test)
  await runSelectedTest()
}

const toggleFeature = (featureId) => {
  if (expandedFeatures.value.has(featureId)) {
    expandedFeatures.value.delete(featureId)
  } else {
    expandedFeatures.value.add(featureId)
  }
  expandedFeatures.value = new Set(expandedFeatures.value)
}

const handleRunFeature = async (featureId) => {
  try {
    await testStore.runFeature(featureId, testStore.testRunConfig)
    await testStore.refreshTestsFromBackend()
    await testStore.refreshFeaturesFromBackend()
  } catch (err) {
    console.error('Failed to run feature:', err)
  }
}

const handleDeleteFeature = async (featureId) => {
  const feature = features.value.find(f => f.id === featureId)
  if (!feature) return
  if (!confirm(`Delete feature ${feature.name}? All tests inside will also be deleted.`)) return
  await testStore.deleteFeature(featureId)
  await testStore.refreshTestsFromBackend()
  await testStore.refreshFeaturesFromBackend()
  alert(`Feature ${feature.name} deleted successfully.`)
  if (tests.value.length > 0) {
    const featureTest = features.value.flatMap(f => f.tests)[0]
    const nextTest = featureTest ? tests.value.find(t => t.id === featureTest.id) : tests.value[0]
    testStore.setSelectedTest(nextTest)
    const parentFeature = features.value.find(f => f.tests.some(t => t.id === nextTest.id))
    if (parentFeature) {
      expandedFeatures.value.add(parentFeature.id)
      expandedFeatures.value = new Set(expandedFeatures.value)
    }
  }
}

const handleDeleteTest = async (testId) => {
  const test = tests.value.find(t => t.id === testId)
  if (!confirm(`Delete test ${test.title?.split('_').slice(0, -1).join('_') || test.title}? All run history will also be deleted.`)) return
  const parentFeature = features.value.find(f => f.tests.some(t => t.id === testId))
  await testStore.deleteTest(testId)
  await testStore.refreshTestsFromBackend()
  await testStore.refreshFeaturesFromBackend()
  alert(`Test ${test.title?.split('_').slice(0, -1).join('_') || test.title} deleted successfully.`)
  if (tests.value.length > 0) {
    const featureTest = features.value.flatMap(f => f.tests)[0]
    const nextTest = tests.value.find(t => t.id === featureTest?.id) || tests.value[0]
    testStore.setSelectedTest(nextTest)
    if (parentFeature) expandedFeatures.value.delete(parentFeature.id)
    const nextFeature = features.value.find(f => f.tests.some(t => t.id === nextTest.id))
    if (nextFeature) expandedFeatures.value.add(nextFeature.id)
    expandedFeatures.value = new Set(expandedFeatures.value)
  }
}

const handleViewHistory = async (feature) => {
  featureHistoryRef.value?.show(feature)
  await testStore.refreshTestsFromBackend()
}

const getStandaloneTests = () => {
  const featureTestIds = new Set(filteredFeatures.value.flatMap(f => f.tests.map(t => t.id)))
  return filteredTests.value.filter(t => !featureTestIds.has(t.id))
}
</script>

<template>
  <Card class="w-full lg:w-[25%] rounded-lg overflow-hidden flex flex-col lg:h-[calc(100vh-7rem)] lg:min-h-0">
    <CardHeader class="bg-[#1c2333] shrink-0">
      <CardTitle class="font-bold text-sm">Test Scripts</CardTitle>
      <CardDescription class="text-xs text-slate-500">
  {{ visibleTestCount }} of {{ totalTestCount }} tests
      </CardDescription>
    </CardHeader>
    <Separator />

    <CardContent class="bg-[#161b26] flex-1 overflow-hidden flex flex-col p-0 min-h-0">
      <div class="px-4">
        <PassFailCountCard
          :passCnt="passCnt"
          :failCnt="failCnt"
          :runCnt="runCnt"
          :queueCnt="queueCnt"
        />
      </div>

      <!-- Scrollable test list — fills remaining height -->
      <ScrollArea class="flex-1 min-h-0 mt-4 h-full">
        <div class="px-3 pb-3 flex flex-col gap-1">

          <!-- Features -->
          <div v-for="feature in filteredFeatures" :key="feature.id">
            <!-- Feature header — keyboard accessible -->
            <div
              role="button"
              tabindex="0"
              :aria-expanded="expandedFeatures.has(feature.id)"
              :class="[
                'flex flex-col gap-3 px-3 py-3 rounded-lg cursor-pointer transition-all duration-200 select-none',
                expandedFeatures.has(feature.id)
                  ? 'bg-[#2a3347] border border-slate-600/50'
                  : 'bg-[#1c2333] border border-transparent hover:bg-[#2a3347]'
              ]"
              @click="toggleFeature(feature.id)"
              @keydown.enter.prevent="toggleFeature(feature.id)"
              @keydown.space.prevent="toggleFeature(feature.id)"
            >
              <!-- Name row -->
              <div class="flex items-center gap-2">
                <ChevronDown v-if="expandedFeatures.has(feature.id)" class="w-3.5 h-3.5 text-slate-400 shrink-0" />
                <ChevronRight v-else class="w-3.5 h-3.5 text-slate-400 shrink-0" />
                <span class="text-sm font-semibold text-white truncate">{{ feature.name }}</span>
                <span class="text-xs text-slate-600 shrink-0">({{ feature.tests.length }})</span>
              </div>

              <!-- Action buttons row -->
              <div class="flex items-center gap-1.5 pl-5" @click.stop @keydown.enter.stop @keydown.space.stop>
                <button
                  class="h-7 w-7 rounded flex items-center justify-center
                         bg-[#2a3347]/50 hover:bg-[#2a3347] text-slate-400 hover:text-white
                         transition-colors focus:outline-none focus:ring-1 focus:ring-slate-500"
                  title="Run all tests"
                  @click="handleRunFeature(feature.id)"
                >
                  <Play class="w-3 h-3" />
                </button>
                <button
                  class="h-7 w-7 rounded flex items-center justify-center
                         bg-[#2a3347]/50 hover:bg-[#2a3347] text-slate-400 hover:text-white
                         transition-colors focus:outline-none focus:ring-1 focus:ring-slate-500"
                  title="View run history"
                  @click="handleViewHistory(feature)"
                >
                  <History class="w-3 h-3" />
                </button>
                <button
                  class="h-7 w-7 rounded flex items-center justify-center
                         bg-[#2a3347]/50 hover:bg-[#2a3347] text-slate-400 hover:text-white
                         transition-colors focus:outline-none focus:ring-1 focus:ring-slate-500"
                  title="Feature settings"
                  @click="handleOpenSettings(feature)"
                >
                  <Settings class="w-3 h-3" />
                </button>
                <button
                  class="h-7 w-7 rounded flex items-center justify-center
                         bg-[#2a3347]/50 hover:bg-[#2a3347] text-slate-400 hover:text-white
                         transition-colors focus:outline-none focus:ring-1 focus:ring-slate-500"
                  title="Delete feature"
                  @click="handleDeleteFeature(feature.id)"
                >
                  <Trash2 class="w-3 h-3" />
                </button>
              </div>
            </div>

            <!-- Feature tests -->
            <div v-if="expandedFeatures.has(feature.id)" class="ml-3 mt-1 flex flex-col gap-1 border-l border-slate-800 pl-2">
              <div v-for="test in feature.tests" :key="test.id">
                <TestCard
                  :tests="tests.find(t => t.id === test.id) || test"
                  :class="selectedTest?.id === test.id
                    ? 'border-l-slate-400 bg-[#2a3347]'
                    : ''"
                  @click="testStore.setSelectedTest(tests.find(t => t.id === test.id) || test)"
                  @action="handleRunTest(tests.find(t => t.id === test.id) || test)"
                  @delete="handleDeleteTest(test.id)"
                />
              </div>
            </div>
          </div>

          <!-- Standalone separator -->
          <div
            v-if="filteredFeatures.length > 0 && getStandaloneTests().length > 0"
            class="flex items-center gap-2 my-2"
          >
            <Separator class="flex-1" />
            <span class="text-[10px] text-slate-600 uppercase tracking-widest">Standalone</span>
            <Separator class="flex-1" />
          </div>

          <!-- Standalone tests -->
          <div v-for="test in getStandaloneTests()" :key="test.id">
            <TestCard
              :tests="test"
              :class="selectedTest?.id === test.id ? 'border-l-slate-400 bg-[#2a3347]' : ''"
              @click="testStore.setSelectedTest(test)"
              @action="handleRunTest(test)"
              @delete="handleDeleteTest(test.id)"
            />
          </div>

          <!-- Empty state -->
          <div
            v-if="filteredTests.length === 0 && filteredFeatures.length === 0"
            class="py-8 text-center text-slate-600 text-sm"
          >
            No tests match your search.
          </div>
        </div>
      </ScrollArea>
    </CardContent>

    <CardFooter class="bg-[#161b26] border-t border-slate-800 shrink-0">
      <InformationalTip />
    </CardFooter>
  </Card>

  <FeatureRunHistory ref="featureHistoryRef" />
  <FeatureSettingsModal ref="featureSettingsRef" />
</template>