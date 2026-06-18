<template>
  <div class="flex flex-col lg:flex-row mt-0 ml-5 mr-5 gap-4 bg-[#161b26]">

    <!-- Environment -->
    <div class="w-full lg:w-64">
      <label class="mb-1 block text-xs font-medium text-muted-foreground">
        ENVIRONMENT
      </label>
      <select
        class="w-full rounded-lg bg-background px-3 py-2 text-sm"
        :value="environment"
        @change="emit('update:environment', $event.target.value)"
      >
        <option v-for="env in environments" :key="env.value" :value="env.value">
          {{ env.label }}
        </option>
      </select>
    </div>

    <!-- Runner Mode -->
    <div class="w-full lg:w-64">
      <label class="mb-1 block text-xs font-medium text-muted-foreground">
        RUNNER MODE
      </label>
      <select
        class="w-full rounded-lg bg-background px-3 py-2 text-sm"
        :value="runnerMode"
        @change="emit('update:runnerMode', $event.target.value)"
      >
        <option value="headless">Headless (default)</option>
        <!-- <option value="headed">Headed</option> -->
      </select>
    </div>

    <!-- Tags chip input -->
    <div class="w-full lg:w-64">
      <label class="mb-1 block text-xs font-medium text-muted-foreground">
        TAGS
        <span class="ml-1 text-slate-500">({{ tagList.length }}/10)</span>
      </label>
      <div
        class="min-h-[40px] w-full rounded-lg bg-background px-2 py-1.5
               flex flex-wrap gap-1.5 cursor-text border border-transparent
               focus-within:border-slate-600 transition-colors"
        @click="inputRef?.focus()"
      >
        <input
          v-if="tagList.length < 10"
          ref="inputRef"
          v-model="inputVal"
          type="text"
          placeholder="Type tag, press Enter..."
          title="Enter to add tag & Backspace to remove last tag"
          class="flex-1 min-w-[120px] bg-transparent text-sm
                 text-white placeholder:text-slate-500
                 outline-none border-none focus:ring-0 py-0.5"
          @keydown.enter.prevent="addTag"
          @keydown.backspace="handleBackspace"
        />
        
        <span v-else class="text-xs text-slate-500 py-0.5 px-1 self-center">
          Max 10 tags
        </span>
      </div>
    </div>

    <!-- Retries -->
    <div class="w-full lg:w-64">
      <label class="mb-1 block text-xs font-medium text-muted-foreground">
        RETRIES ON FAILURE
      </label>
    
      <select
        class="w-full rounded-lg bg-background px-3 py-2 text-sm"
        :value="retries"
        @change="emit('update:retries', Number($event.target.value))"
      >
        <option v-for="n in 5" :key="n" :value="n - 1">
          {{ n - 1 }}
        </option>
      </select>
    </div>

  </div>
</template>

<script setup>
import { ref, computed } from 'vue'

const props = defineProps({
  environment: String,
  tags: [String, Array],  // accepts both formats
  runnerMode: String,
  retries: Number,
  environments: {
    type: Array,
    default: () => []
  }
})

const emit = defineEmits([
  'update:environment',
  'update:tags',
  'update:runnerMode',
  'update:retries'
])

const inputRef = ref(null)
const inputVal = ref('')

// Normalize tags prop to always be a clean array
const tagList = computed(() => {
  if (!props.tags) return []
  if (Array.isArray(props.tags)) return props.tags
  return props.tags.split(',').map(t => t.trim()).filter(Boolean)
})

function addTag() {
  const val = inputVal.value.trim()
  if (!val) return
  if (tagList.value.length >= 10) return
  if (tagList.value.includes(val)) {
    inputVal.value = ''  // clear duplicate silently
    return
  }
  emit('update:tags', [...tagList.value, val])
  inputVal.value = ''  // clear input after adding
}

// Backspace on empty input removes last tag
function handleBackspace() {
  if (inputVal.value === '' && tagList.value.length > 0) {
    emit('update:tags', tagList.value.slice(0, -1))
  }
}
</script>