<script setup>
import { Button } from "@/components/ui/button"
const props = defineProps({
  title: {
    type: String,
    required: true
  },
  path: {
    type: String,
    required: true
  },
  icon: {
    type: String,
    required: true
  }
})
const download = async () => {
  try {
    const response = await fetch(props.path)
    const blob = await response.blob()
    const url = URL.createObjectURL(blob)

    const a = document.createElement('a')
    a.href = url
    a.download = props.title
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    URL.revokeObjectURL(url)
  } catch (err) {
    console.error('Download failed:', err)
  }
}
</script>

<template>
  <div
    class="flex flex-col gap-4 rounded-xl
       bg-[#1c2333]
    border border-slate-800
           px-6 py-5 sm:flex-row sm:items-center sm:justify-between"
  >
    <div class="flex items-center gap-4">
      <div
        class="flex h-12 w-12 items-center justify-center
               rounded-xl bg-slate-800 text-xl"
      >
        {{ icon }}
      </div>
      <div>
        <p class="text-base font-semibold text-white">
          {{ title }}
        </p>
        <p class="text-sm text-slate-400
         break-all sm:break-words">
          {{ path }}
        </p>
      </div>
    </div>
    <Button
      variant="secondary"
      class="self-start sm:self-auto focus-visible:ring-white"
      @click="download"
    >
      Download
    </Button>
  </div>
</template>
