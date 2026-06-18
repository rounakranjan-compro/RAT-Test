<script setup>
import { computed, ref, watch } from 'vue'
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import Button from './ui/button/Button.vue'
import { Trash2, ArrowLeft } from 'lucide-vue-next'
import Input from './ui/input/Input.vue'
import axios from '@/plugins/axios.js'
import { useTestStore } from '@/stores/testStore'

const testStore = useTestStore()
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL

const open = ref(false)
const filename = ref('')
const pastedText = ref('')
const currFileInp = ref(null)
const savedFileName = ref('')
const featureEntryMode = ref('existing')
const selectedFeatureName = ref('')
const newFeatureName = ref('')
const fileNameError = ref('')
const featureError = ref('')
const submissionError = ref('')
const step = ref(1)
const importType = ref('')

const hasSelectedFile = computed(() => filename.value.length > 0)
const hasPastedText = computed(() => pastedText.value.trim().length > 0)
const featureNamePattern = /^[A-Za-z][A-Za-z0-9]*$/

const featureOptions = computed(() => {
  return [...(testStore.features || [])]
    .map(feature => feature?.name?.trim())
    .filter(Boolean)
    .sort((left, right) => left.localeCompare(right))
})

const hasError = computed(() => Boolean(fileNameError.value || featureError.value || submissionError.value))
const errorMessage = computed(() => fileNameError.value || featureError.value || submissionError.value)
const canSave = computed(() => {
  const fileName = savedFileName.value.trim()
  const hasContent = hasSelectedFile.value || hasPastedText.value

  if (!featureNamePattern.test(fileName) || !hasContent) {
    return false
  }

  if (importType.value !== 'feature') {
    return true
  }

  if (featureEntryMode.value === 'existing') {
    return Boolean(selectedFeatureName.value)
  }

  return featureNamePattern.test(newFeatureName.value.trim())
})

const resetFeatureState = () => {
  featureEntryMode.value = featureOptions.value.length ? 'existing' : 'new'
  selectedFeatureName.value = ''
  newFeatureName.value = ''
}

const resetFormState = () => {
  filename.value = ''
  pastedText.value = ''
  currFileInp.value = null
  savedFileName.value = ''
  fileNameError.value = ''
  featureError.value = ''
  submissionError.value = ''
  step.value = 1
  importType.value = ''
  resetFeatureState()
}

const normalizeFeatureName = (value) => {
  const trimmed = value.trim()
  const matchedFeature = featureOptions.value.find(
    option => option.toLowerCase() === trimmed.toLowerCase(),
  )

  return matchedFeature || trimmed
}

const validateFileName = (showRequired = false) => {
  const value = savedFileName.value.trim()

  if (!value) {
    fileNameError.value = showRequired ? 'File name is required' : ''
    return false
  }

  if (!featureNamePattern.test(value)) {
    fileNameError.value = 'File name must start with a letter and contain only letters or numbers'
    return false
  }

  fileNameError.value = ''
  return true
}

const validateFeatureInput = (showRequired = false) => {
  if (importType.value !== 'feature') {
    featureError.value = ''
    return true
  }

  if (featureEntryMode.value === 'existing') {
    if (!selectedFeatureName.value) {
      featureError.value = showRequired
        ? 'Please choose an existing feature or switch to create a new one'
        : ''
      return false
    }

    featureError.value = ''
    return true
  }

  const value = newFeatureName.value.trim()

  if (!value) {
    featureError.value = showRequired ? 'Feature name is required' : ''
    return false
  }

  if (!featureNamePattern.test(value)) {
    featureError.value = 'Feature name must start with a letter and contain only letters or numbers'
    return false
  }

  featureError.value = ''
  return true
}

const syncFeatureSelection = () => {
  if (importType.value !== 'feature') return

  if (featureEntryMode.value === 'existing') {
    if (selectedFeatureName.value) {
      selectedFeatureName.value = normalizeFeatureName(selectedFeatureName.value)
    }
  }
}

const show = () => {
  open.value = true
  resetFormState()

  if (!testStore.features.length) {
    void testStore.refreshFeaturesFromBackend()
  }
}

const close = () => {
  open.value = false
  resetFormState()
}

const selectImportType = (type) => {
  importType.value = type
  step.value = 2

  if (type === 'feature') {
    resetFeatureState()
  }
}

const goBack = () => {
  step.value = 1
  importType.value = ''
  featureError.value = ''
  submissionError.value = ''
  filename.value = ''
  pastedText.value = ''
  currFileInp.value = null
  savedFileName.value = ''
  fileNameError.value = ''
}

const handleFileChange = (e) => {
  const input = e.target
  const file = input.files?.[0]
  if (!file) return

  const allowedExt = ['spec.js']
  const parts = file.name.split('.')
  const lastExt = parts.length > 1 ? parts.pop().toLowerCase() : ''
  const secondLastExt = parts.length > 1 ? parts.pop().toLowerCase() : ''
  const ext = `${secondLastExt}.${lastExt}`
  const isValid = allowedExt.includes(ext)

  if (!isValid) {
    input.value = ''
    filename.value = ''
    alert('Invalid file type. Please select a .spec.js file.')
    return
  }

  filename.value = file.name
}

const removeSelection = () => {
  if (currFileInp.value) {
    currFileInp.value.value = ''
  }

  filename.value = ''
  currFileInp.value = null
}

const save = async () => {
  submissionError.value = ''

  if (!validateFileName(true)) {
    return
  }

  if (!hasSelectedFile.value && !hasPastedText.value) {
    submissionError.value = 'Please select a file or paste a script'
    return
  }

  if (!validateFeatureInput(true)) {
    return
  }

  const featureNameToSave = importType.value === 'feature'
    ? (featureEntryMode.value === 'existing'
      ? normalizeFeatureName(selectedFeatureName.value)
      : newFeatureName.value.trim())
    : null

  let scriptContent = ''

  try {
    if (hasSelectedFile.value) {
      scriptContent = await new Promise((resolve, reject) => {
        const reader = new FileReader()
        reader.onload = (event) => resolve(event.target.result)
        reader.onerror = () => reject(new Error('Failed to read file'))
        reader.readAsText(currFileInp.value.files[0])
      })
    } else {
      scriptContent = pastedText.value
    }

    const res = await axios.post(`${API_BASE_URL}/api/import_tests`, {
      saved_filename: savedFileName.value.trim(),
      saved_script_content: scriptContent,
      feature_name: featureNameToSave,
    })

    if (res.data.feature) {
      await testStore.refreshFeaturesFromBackend()
    }

    await testStore.refreshTestsFromBackend()
    close()
  } catch (err) {
    if (err.response?.data?.error) {
      submissionError.value = err.response.data.error
    } else {
      submissionError.value = 'An error occurred. Please try again.'
    }
  }
}

watch(savedFileName, () => {
  submissionError.value = ''
  validateFileName()
})

watch(featureEntryMode, () => {
  featureError.value = ''

  if (featureEntryMode.value === 'existing') {
    newFeatureName.value = ''
  } else {
    selectedFeatureName.value = ''
  }
})

watch(selectedFeatureName, () => {
  submissionError.value = ''
  featureError.value = ''
  syncFeatureSelection()
})

watch(newFeatureName, () => {
  submissionError.value = ''

  if (featureEntryMode.value !== 'new') return

  validateFeatureInput()
})

defineExpose({ show })
</script>

<template>
  <Dialog v-model:open="open">
    <DialogContent class="max-h-[95vh] max-w-sm overflow-hidden flex flex-col">
      <DialogHeader class="flex flex-row gap-4">
        <div v-if="step === 2" class="cursor-pointer" @click="goBack">
          <ArrowLeft />
        </div>
        <DialogTitle>Import Test</DialogTitle>
      </DialogHeader>

      <div :key="step">
        <div v-if="step === 1" class="py-6">
          <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
            <div
              class="border rounded-xl p-6 cursor-pointer transition bg-[#1c2333] min-h-[160px]"
              :class="
                importType === 'standalone'
                  ? 'border-primary bg-muted'
                  : 'hover:border-primary'
              " tabindex="0"
              @click="selectImportType('standalone')" @keypress.enter="selectImportType('standalone')"
            >
              <h3 class="font-semibold text-lg">Standalone</h3>

              <p class="text-sm text-muted-foreground mt-2 text-wrap">
                Import test without feature grouping
              </p>
            </div>

            <div
              class="border rounded-xl p-6 cursor-pointer transition bg-[#1c2333] min-h-[160px]"
              :class="
                importType === 'feature'
                  ? 'border-primary bg-muted'
                  : 'hover:border-primary'
              "
              @click="selectImportType('feature')"
              @keypress="selectImportType('feature')"
              tabindex="0"
            >
              <h3 class="font-semibold text-lg">Feature</h3>

              <p class="text-sm text-muted-foreground mt-2 text-wrap">
                Import test under a feature
              </p>
            </div>
          </div>
        </div>

        <template v-if="step === 2">
          <div class="mt-3 overflow-y-auto flex-1 p-1.5 space-y-2.5" tabindex="-1">
            <input
              ref="currFileInp"
              type="file"
              @change="handleFileChange"
              :disabled="hasPastedText"
              class="flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50 cursor-pointer"
            />

            <div v-if="filename" class="mt-2 flex gap-2 flex-wrap">
              <p class="text-sm text-green-500 mt-2 text-wrap">Selected file: {{ filename }}</p>
              <Button variant="destructive" size="icon" @click="removeSelection" class="text-red-500">
                <Trash2 class="w-4 h-4" />
              </Button>
            </div>

            <p class="text-center mt-2 mb-2 text-sm font-semibold">OR</p>

            <textarea
              v-model="pastedText"
              placeholder="Paste your test script here..."
              rows="5"
              :disabled="hasSelectedFile"
              class="flex min-h-[100px] w-full rounded-md border border-input bg-transparent px-3 py-2 text-sm shadow-sm placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50 resize-y max-h-[180px]"
            />
          </div>

          <br/>

          <div class="mt-1.5 flex flex-col gap-2">
            <Input
              placeholder="Enter file name to be saved (without extension)"
              v-model="savedFileName"
              @input="validateFileName"
            />

            <br/>
            <div v-if="importType === 'feature'" class="space-y-2 rounded-lg border border-white/10 bg-[#161b26] p-3">
              <div class="flex items-center justify-between gap-3">
                <p class="text-sm font-medium">Feature</p>
                <div class="inline-flex rounded-full border border-white/10 p-0.5 text-sm gap-0.5">
                  <button
                    type="button"
                    class="rounded-full px-3 py-1 transition font-medium"
                    :class="featureEntryMode === 'existing' ? 'bg-primary text-primary-foreground' : 'text-muted-foreground'"
                    @click="featureEntryMode = 'existing'"
                  >
                    Pick
                  </button>
                  <button
                    type="button"
                    class="rounded-full px-3 py-1 transition font-medium"
                    :class="featureEntryMode === 'new' ? 'bg-primary text-primary-foreground' : 'text-muted-foreground'"
                    @click="featureEntryMode = 'new'"
                  >
                    New
                  </button>
                </div>
              </div>

              <div v-if="featureEntryMode === 'existing'" class="max-h-[140px] overflow-y-auto rounded-md border border-input">
                <select
                  v-model="selectedFeatureName"
                  class="w-full bg-background px-3 py-2 text-sm focus-visible:outline-violet-600 focus-visible:ring-1 focus-visible:ring-ring" tabindex="0"
                >
                  <option value="">Choose an existing feature</option>
                  <option v-for="feature in featureOptions" :key="feature" :value="feature">
                    {{ feature }}
                  </option>
                </select>
              </div>

              <Input
                v-else
                placeholder="Feature name"
                v-model="newFeatureName"
                @input="validateFeatureInput"
              />

              <p v-if="featureEntryMode === 'existing' && !featureOptions.length" class="text-xs text-muted-foreground mt-1">
                No features yet. Switch to New.
              </p>

              <p v-if="featureEntryMode === 'new'" class="text-xs text-muted-foreground mt-1">
                Create with any casing. Letters and numbers only.
              </p>
            </div>

            <p v-if="hasError" class="text-sm text-red-500 mt-1">{{ errorMessage }}</p>
          </div>

          <DialogFooter class="mt-4 gap-2 flex-col sm:flex-row sm:justify-end">
            <Button variant="outline" @click="close">Cancel</Button>
            <Button :disabled="!canSave || hasError" @click="save">Save</Button>
          </DialogFooter>
        </template>
      </div>
    </DialogContent>
  </Dialog>
</template>