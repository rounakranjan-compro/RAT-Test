<template>
  <Dialog v-model:open="open">
    <DialogContent class="sm:max-w-md">
      <DialogHeader>
        <DialogTitle>Record New Test</DialogTitle>
      </DialogHeader>

      <div class="space-y-2">
        <label class="text-sm text-muted-foreground">
          Test file name
        </label>

        <Input
          v-model="fileName"
          placeholder="loginTest"
          @input="validate"
        />

        <p class="text-xs text-muted-foreground">
          Only letters & numbers allowed. <br />  
        </p>

         <p class="text-xs text-muted-foreground">
         <b>Note:</b> Please close the recording browser to stop recording. <br />  
        </p>

        <p v-if="error" class="text-sm text-red-500">
          {{ error }}
        </p>
      </div>

      <DialogFooter class="mt-4">
        <Button variant="outline" @click="close">
          Cancel
        </Button>

        <Button
          :disabled="!!error || !fileName"
          @click="save"
        >
          Save
        </Button>
      </DialogFooter>
    </DialogContent>
  </Dialog>
</template>

<script setup>
import { ref } from 'vue'
import axios from '@/plugins/axios.js'

import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter
} from '@/components/ui/dialog'

import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'



const open = ref(false)
const fileName = ref('')
const error = ref('')

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL

const emit = defineEmits(['test-created'])

const show = () => {
  fileName.value = ''
  error.value = ''
  open.value = true
}

const close = () => {
  open.value = false
}

const validate = () => {
  const value = fileName.value
  if (!value) {
    error.value = ''
    return
  }
  if (!/^[A-Za-z][A-Za-z0-9]*$/.test(value)) {
    error.value = 'File name must start with a letter and contain only letters or numbers'
    return
  }
  error.value = ''
}

const save = async () => {
  if (error.value || !fileName.value) return
  try {
    const response = await axios.post(`${API_BASE_URL}/api/record_tests`, {
      title: fileName.value
    })
    emit('test-created', response.data.new_test)
    close()
  } catch (err) {
    error.value = err.response?.data?.error || 'Something went wrong'
  } 
}

defineExpose({ show })
</script>
