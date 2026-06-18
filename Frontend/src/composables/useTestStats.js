import { computed } from 'vue'

export function useTestStats(tests) {
  const passCnt = computed(() =>
    tests.value.filter(t => t.status === 'passed').length
  )

  const failCnt = computed(() =>
    tests.value.filter(t => t.status === 'failed').length
  )

  const runCnt = computed(() =>
    tests.value.filter(t => t.status === 'running').length
  )

  const totalCnt = computed(() => tests.value.length)

  const queueCnt = computed(() =>
    tests.value.filter(t => t.status === 'queued').length
  )

  return {
    passCnt,
    failCnt,
    runCnt,
    queueCnt,
    totalCnt
  }
}