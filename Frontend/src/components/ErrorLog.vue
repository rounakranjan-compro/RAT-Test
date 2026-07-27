<script setup>
import { computed, ref } from "vue"
import {
  Card,
  CardHeader,
  CardTitle,
  CardContent,
} from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"

const props = defineProps({
  error: {
    type: Object,
    default: null,
  },
})

const expanded = ref(false)
const copied = ref(false)

const formattedJson = computed(() =>
  JSON.stringify(props.error, null, 2)
)

const severity = computed(() => {
  const status = props.error?.status || props.error?.status_code

  if (status >= 500) return "Critical"
  if (status >= 400) return "Error"
  if (status >= 300) return "Warning"

  return "Info"
})

const badgeVariant = computed(() => {
  switch (severity.value) {
    case "Critical":
      return "destructive"
    case "Error":
      return "destructive"
    case "Warning":
      return "secondary"
    default:
      return "outline"
  }
})

const copyToClipboard = async () => {
  await navigator.clipboard.writeText(formattedJson.value)
  copied.value = true

  setTimeout(() => {
    copied.value = false
  }, 2000)
}

const downloadJson = () => {
  const blob = new Blob([formattedJson.value], {
    type: "application/json",
  })

  const url = URL.createObjectURL(blob)

  const link = document.createElement("a")
  link.href = url
  link.download = `error-log-${Date.now()}.json`
  link.click()

  URL.revokeObjectURL(url)
}
</script>

<template>
  <Card
    v-if="error"
    class="border-red-900 bg-gradient-to-br from-slate-900 via-slate-950 to-black shadow-xl"
  >
    <CardHeader
      class="border-b border-slate-800 flex flex-col gap-4 md:flex-row md:justify-between md:items-center"
    >
      <div class="space-y-2">
        <CardTitle class="flex items-center gap-2 text-red-400">
          🚨 Error Log

          <Badge :variant="badgeVariant">
            {{ severity }}
          </Badge>
        </CardTitle>

        <div class="text-xs text-slate-400">
          {{ new Date().toLocaleString() }}
        </div>
      </div>

      <div class="flex flex-wrap gap-2">
        <Button
          size="sm"
          variant="secondary"
          @click="expanded = !expanded"
        >
          {{ expanded ? "Hide JSON" : "View JSON" }}
        </Button>

        <Button
          size="sm"
          variant="outline"
          @click="copyToClipboard"
        >
          {{ copied ? "Copied!" : "Copy" }}
        </Button>

        <Button
          size="sm"
          variant="outline"
          @click="downloadJson"
        >
          Download
        </Button>
      </div>
    </CardHeader>

    <CardContent class="space-y-4 pt-5">

      <div class="grid md:grid-cols-3 gap-4">

        <div
          class="rounded-lg border border-slate-800 bg-slate-900 p-3"
        >
          <div class="text-xs text-slate-400">
            Message
          </div>

          <div class="mt-1 text-sm text-red-300 break-words">
            {{ error.message || "-" }}
          </div>
        </div>

        <div
          class="rounded-lg border border-slate-800 bg-slate-900 p-3"
        >
          <div class="text-xs text-slate-400">
            Status
          </div>

          <div class="mt-1 font-semibold text-white">
            {{ error.status || error.status_code || "-" }}
          </div>
        </div>

        <div
          class="rounded-lg border border-slate-800 bg-slate-900 p-3"
        >
          <div class="text-xs text-slate-400">
            Error Code
          </div>

          <div class="mt-1 font-semibold text-white">
            {{ error.code || "-" }}
          </div>
        </div>

      </div>

      <Transition name="fade">

        <div
          v-if="expanded"
          class="rounded-lg border border-slate-800 bg-black p-4"
        >
          <pre
            class="max-h-[500px] overflow-auto whitespace-pre-wrap break-all text-sm text-green-300 font-mono"
          >
{{ formattedJson }}
          </pre>
        </div>

      </Transition>

    </CardContent>
  </Card>
</template>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: all .25s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
  transform: translateY(-8px);
}
</style>