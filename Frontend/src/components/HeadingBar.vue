<template>
  <div
    class="flex items-start justify-between
           rounded-xl bg-[#1c2333] border border-slate-800
           px-6 py-4 gap-4"
  >
    <div class="flex-1 min-w-0">
      <!-- Test Name + Feature Badge -->
      <div class="flex items-center gap-3 flex-wrap">
        <h1 class="text-xl font-bold text-white">
          {{ title?.split('_').slice(0, -1).join('_') || title }}
        </h1>

        <div
          class="inline-flex items-center gap-2 px-3 py-1 rounded-full border border-slate-700 bg-slate-700/30 transition-colors"
        >
          <span class="h-1.5 w-1.5 rounded-full bg-slate-400" />

          <span class="text-xs font-semibold uppercase tracking-widest text-slate-300">
            {{ featureName }}
          </span>
        </div>
      </div>

      <div class="mt-2 flex flex-wrap items-center gap-1.5">
        <!-- Tag chips with cross -->
        <span
          v-for="(tag, index) in tags"
          :key="index"
          class="inline-flex items-center gap-1 rounded-md
                 bg-slate-700/40 border border-slate-600/40
                 px-2 py-0.5 text-xs text-slate-300"
        >
          <span class="break-all max-w-[150px]">{{ tag }}</span>
          <button
            type="button"
            class="ml-0.5 text-slate-400 hover:text-white
                   transition-colors leading-none"
            @click.stop="removeTag(index)"
          >
            ×
          </button>
        </span>

        <span v-if="!tags?.length" class="text-xs text-slate-500">
          No tags — type in the field below and press Enter
        </span>

        <span
          v-if="tags?.length && environment"
          class="mx-1 text-slate-600"
        >
          •
        </span>

        <span v-if="environment" class="text-sm text-slate-400">
          {{ environment }}
        </span>
      </div>
    </div>

    <div class="flex items-center gap-3 shrink-0">
      <button
        :disabled="isThisTestBusy"
        class="inline-flex items-center gap-2 rounded-md px-4 py-2 text-sm font-medium
               bg-slate-100 text-slate-900 hover:bg-white transition-colors
               disabled:opacity-40 disabled:cursor-not-allowed focus-visible:ring-2 focus-visible:ring-purple-500 focus-visible:ring-offset-2 focus-visible:ring-offset-slate-900 focus-visible:outline-none"
        @click="runTest"
      >
        <template v-if="isThisTestBusy">
          <Loader2 class="w-4 h-4 animate-spin" />
          Running…
        </template>
        <template v-else>
          <Play class="w-4 h-4" />
          Run Test
        </template>
      </button>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { Play, Loader2 } from 'lucide-vue-next'
import { useTestStore } from '@/stores/testStore'
import { storeToRefs } from 'pinia'
import { useTestOperations } from '@/composables/useTestOperations'

const props = defineProps({
  title: String,
  tags: Array,
  environment: String
})

const emit = defineEmits(['removeTag'])

const { runSelectedTest: runTest } = useTestOperations()
const { queuedRuns, selectedTest, tests, features } = storeToRefs(useTestStore())

const isThisTestBusy = computed(() => {
  return selectedTest.value?.status === 'running' ||
         queuedRuns.value.includes(selectedTest.value?.id)
})

const featureName = computed(() => {
  const feature = features.value.find(f => 
    f.tests.some(t => t.id === selectedTest.value?.id)
  )
  return feature?.name || 'Standalone'
})

function removeTag(index) {
  emit('removeTag', index)
}
</script>