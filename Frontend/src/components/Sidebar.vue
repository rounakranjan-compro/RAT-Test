<script setup>
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import Separator from './ui/separator/Separator.vue'
import PassFailCountCard from './PassFailCountCard.vue'
import TestCard from './TestCard.vue'
import InformationalTip from './InformationalTip.vue'
import FeatureRunHistory from './FeatureRunHistory.vue'
import { onMounted, ref } from 'vue'
import { useTestStore } from '@/stores/testStore'
import { storeToRefs } from 'pinia'
import { useTestFilter } from '@/composables/useTestFilter'
import { useTestStats } from '@/composables/useTestStats'
import { useTestOperations } from '@/composables/useTestOperations'
import ScrollArea from './ui/scroll-area/ScrollArea.vue'
import { ChevronDown, ChevronRight, Play, Trash2, History, Settings } from 'lucide-vue-next'
import Button from './ui/button/Button.vue'
import FeatureSettingsModal from './FeatureSettingsModal.vue'

const featureSettingsRef = ref(null)
const testStore = useTestStore()
const { tests, features, selectedTest, searchQuery } = storeToRefs(testStore)
const { runSelectedTest } = useTestOperations()

const expandedFeatures = ref(new Set())
const featureHistoryRef = ref(null)

onMounted(async () => {
  await Promise.all([
    testStore.refreshTestsFromBackend(),
    testStore.refreshFeaturesFromBackend()
  ])
  if (tests.value.length > 0) {
    testStore.setSelectedTest(tests.value[0])
  }
})

const handleOpenSettings = (feature) => {
  featureSettingsRef.value?.show(feature)
}
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
  if (!confirm('Delete this feature? This will result in all tests deletion.')) return
  await testStore.deleteFeature(featureId)
  await testStore.refreshTestsFromBackend()
  await testStore.refreshFeaturesFromBackend()
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
  if (!confirm('Delete this test?')) return
  const parentFeature = features.value.find(f => f.tests.some(t => t.id === testId))
  await testStore.deleteTest(testId)
  await testStore.refreshTestsFromBackend()
  await testStore.refreshFeaturesFromBackend()
  if (tests.value.length > 0) {
    const featureTest = features.value.flatMap(f => f.tests)[0]
    const nextTest = tests.value.find(t => t.id === featureTest?.id) || tests.value[0]
    testStore.setSelectedTest(nextTest)
    // Update expanded features
    if (parentFeature) {
      expandedFeatures.value.delete(parentFeature.id)
    }
    const nextFeature = features.value.find(f => f.tests.some(t => t.id === nextTest.id))
    if (nextFeature) {
      expandedFeatures.value.add(nextFeature.id)
    }
    expandedFeatures.value = new Set(expandedFeatures.value)
  }
}

const handleViewHistory = async (feature) => {
  featureHistoryRef.value?.show(feature)
  await testStore.refreshTestsFromBackend()
}

const getStandaloneTests = () => {
  const featureTestIds = new Set(
    filteredFeatures.value.flatMap(f => f.tests.map(t => t.id))
  )
  return filteredTests.value.filter(t => !featureTestIds.has(t.id))
}

const statusColor = (status) => {
  switch (status) {
    case 'passed':  return 'text-green-500'
    case 'failed':  return 'text-red-500'
    case 'running': return 'text-yellow-500'
    case 'queued':  return 'text-blue-400'
    default:        return 'text-slate-400'
  }
}
</script>

<template>
  <Card class="mt-36 lg:mt-0 w-full lg:w-[25%] rounded-lg overflow-hidden">
    <CardHeader class="bg-[#1c2333]">
      <CardTitle class="font-bold">Test Scripts</CardTitle>
      <CardDescription class="text-xs text-slate-500 font-semibold">
        {{ (filteredTests.length + filteredFeatures.reduce((acc, f) => acc + f.tests.length, 0)) }} of {{ tests.length + features.reduce((acc, f) => acc + f.tests.length, 0) }} tests
      </CardDescription>
    </CardHeader>
    <Separator />
    <CardContent class="bg-[#161b26]">
      <PassFailCountCard
        :passCnt="passCnt"
        :failCnt="failCnt"
        :runCnt="runCnt"
        :queueCnt="queueCnt"
      />
      <ScrollArea class="h-[28rem] w-full mt-5">
        <div class="pr-3 flex flex-col gap-2">

        <!-- Features -->
<!-- Features -->
          <div v-for="feature in filteredFeatures" :key="feature.id">
            <!-- Feature Header -->
            <div
                :class="[
                'flex flex-col items-center gap-5 text-lg font-bold justify-center px-4 py-4 rounded-md cursor-pointer transition-all duration-200',
                expandedFeatures.has(feature.id)
                  ? 'bg-[#1e2d45] border-l-4 border-indigo-500 shadow-md shadow-indigo-900/30'
                  : 'bg-[#1c2333] border-l-4 border-transparent hover:bg-[#2a3347]'
                ]"
              @click="toggleFeature(feature.id)"
            >
              <div class="flex items-center gap-2">
                <ChevronDown v-if="expandedFeatures.has(feature.id)" class="w-4 h-4 text-slate-400 font-bold" />
                <ChevronRight v-else class="w-4 h-4 text-slate-400 font-bold" />
                <span class="text-lg font-bold text-white">{{ feature.name }}</span>
                <span class="text-sm text-slate-500">({{ feature.tests.length }})</span>
              </div>
              <div class="flex flex-wrap justify-center gap-1">
                <!-- Run All button -->
                <Button
                  size="icon"
                  class="h-6 w-6 bg-green-600 hover:bg-green-700"
                  @click.stop="handleRunFeature(feature.id)"
                  title="Run all tests in feature"
                >
                  <Play class="w-3 h-3" />
                </Button>
                <!-- History button -->
                <Button
                  size="icon"
                  class="h-6 w-6 bg-transparent hover:bg-slate-700"
                  @click.stop="handleViewHistory(feature)"
                  title="View run history"
                >
                  <History class="w-3 h-3 text-slate-400" />
                </Button>
                <!-- Delete feature button -->
                <Button
                  size="icon"
                  class="h-6 w-6 bg-transparent hover:bg-red-900"
                  @click.stop="handleDeleteFeature(feature.id)"
                  title="Delete feature"
                >
                  <Trash2 class="w-3 h-3 text-red-500" />
                </Button>
                <Button
  size="icon"
  class="h-6 w-6 bg-transparent hover:bg-slate-700"
  @click.stop="handleOpenSettings(feature)"
  title="Feature settings"
>
  <Settings class="w-3 h-3 text-slate-400" />
</Button>
              </div>
            </div>
            <!-- Feature Tests (collapsible) -->
            <div v-if="expandedFeatures.has(feature.id)" class="ml-4 mt-1 flex flex-col gap-1">
              <div v-for="test in feature.tests" :key="test.id">
                <TestCard
                  :tests="tests.find(t => t.id === test.id) || test"
                  @click="testStore.setSelectedTest(tests.find(t => t.id === test.id) || test)"
                  :class="selectedTest?.id === test.id ? 'border-[#6366f1] border-l-[#8b5cf6]' : ''"
                  @action="handleRunTest(tests.find(t => t.id === test.id) || test)"
                  @delete="handleDeleteTest(test.id)"
                />
              </div>
            </div>
          </div>

          <!-- Separator between features and standalone tests -->
          <div v-if="filteredFeatures.length > 0 && getStandaloneTests().length > 0" class="flex items-center gap-2 my-1">
            <Separator class="flex-1" />
            <span class="text-xs text-slate-500">Standalone</span>
            <Separator class="flex-1" />
          </div>

          <!-- Standalone Tests -->
          <div v-for="test in getStandaloneTests()" :key="test.id">
            <TestCard
              :tests="test"
              @click="testStore.setSelectedTest(test)"
              :class="selectedTest?.id === test.id ? 'border-[#6366f1] border-l-[#8b5cf6]' : ''"
              @action="handleRunTest(test)"
              @delete="handleDeleteTest(test.id)"
            />
          </div>

        </div>
      </ScrollArea>
    </CardContent>
    <CardFooter class="bg-[#161b26]">
      <InformationalTip />
    </CardFooter>
  </Card>

  <!-- Feature Run History Modal -->
  <FeatureRunHistory ref="featureHistoryRef" />
   <FeatureSettingsModal ref="featureSettingsRef" />
</template>