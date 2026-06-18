import { defineStore } from 'pinia'
import { ref } from 'vue'
import axios from '@/plugins/axios.js'

export const useTestStore = defineStore('test', () => {
  const selectedTest = ref(null)
  const searchQuery = ref('')
  const tests = ref([])
  const features = ref([])
  const testRuns = ref([])
  const pollingInterval = ref(null)
  const runEndTime = ref(null)
  const vncOpened = ref(false)
  const API_BASE_URL = import.meta.env.VITE_API_BASE_URL
  const resetNormalization = ref(false)
  const isAnyRunning = ref(false)
  const queuedRuns = ref([])

  const testRunConfig = ref({
    runner_mode: 'headless',
    retries: 2
  })

async function refreshTestsFromBackend() {
  try {
    const [testsRes, runningRes] = await Promise.all([
      axios.get(`${API_BASE_URL}/api/tests`),
      axios.get(`${API_BASE_URL}/api/test_runs/any_running`)
    ])

    isAnyRunning.value = runningRes.data.running
    queuedRuns.value = runningRes.data.queued

    const freshTests = testsRes.data
    const freshIds = new Set(freshTests.map(t => t.id))

    // Remove tests that no longer exist on server
    // (covers deletes that happened server-side)
    for (let i = tests.value.length - 1; i >= 0; i--) {
      if (!freshIds.has(tests.value[i].id)) {
        tests.value.splice(i, 1)  // mutate in place — no re-render of other cards
      }
    }

    // Merge fresh data into existing array
    freshTests.forEach(fresh => {
      const index = tests.value.findIndex(t => t.id === fresh.id)
      if (index !== -1) {
        const existing = tests.value[index]
        tests.value[index] = {
          ...existing,
          status:     fresh.status,
          vnc_url:    fresh.vnc_url,
          artifacts:  fresh.artifacts,
          lastRun:    fresh.lastRun,
          startedAt:  fresh.startedAt,
          finishedAt: fresh.finishedAt,
          duration:   fresh.duration,
        }
      } else {
        tests.value.push(fresh)
      }
    })

    // Update selectedTest poll fields
    if (selectedTest.value) {
      const fresh = freshTests.find(t => t.id === selectedTest.value.id)
      if (fresh) {
        selectedTest.value.status     = fresh.status
        selectedTest.value.vnc_url    = fresh.vnc_url
        selectedTest.value.artifacts  = fresh.artifacts
        selectedTest.value.lastRun    = fresh.lastRun
        selectedTest.value.startedAt  = fresh.startedAt
        selectedTest.value.finishedAt = fresh.finishedAt
        selectedTest.value.duration   = fresh.duration
      } else {
        // Selected test was deleted externally — select first remaining
        selectedTest.value = tests.value.length > 0 ? tests.value[0] : null
      }
    }

  } catch (err) {
    console.error("Failed to refresh tests:", err)
  }
}

  async function refreshFeaturesFromBackend() {
    try {
      const res = await axios.get(`${API_BASE_URL}/api/features`)
      features.value = res.data
    } catch (err) {
      console.error("Failed to refresh features:", err)
    }
  }

  async function runFeature(featureId, config = {}) {
    try {
      const res = await axios.post(`${API_BASE_URL}/api/features/${featureId}/run_all`, {
        environment:        config.environment || 'QA',
        runner_mode:        config.runner_mode || 'headless',
        retries_on_failure: config.retries || 0
      })
      return res.data
    } catch (err) {
      console.error("Failed to run feature:", err)
      throw err
    }
  }

  async function deleteFeature(featureId) {
  try {
    const feature = features.value.find(f => f.id === featureId)
    const featureTestIds = feature?.tests.map(t => t.id) || []

    // Delete all tests first
    await Promise.all(featureTestIds.map(testId => 
      axios.delete(`${API_BASE_URL}/api/tests/${testId}`)
    ))

    // Only delete feature after all tests are gone
    await axios.delete(`${API_BASE_URL}/api/features/${featureId}`)

    // Now update local state
    features.value = features.value.filter(f => f.id !== featureId)
    tests.value = tests.value.filter(t => !featureTestIds.includes(t.id))

    if (featureTestIds.includes(selectedTest.value?.id)) {
      selectedTest.value = tests.value[0] || null
    }
  } catch (err) {
    console.error("Failed to delete feature:", err)
    throw err
  }
}

  async function deleteTest(testId) {
    try {
      await axios.delete(`${API_BASE_URL}/api/tests/${testId}`)
      tests.value = tests.value.filter(t => t.id !== testId)
    } catch (err) {
      console.error("Failed to delete test:", err)
      throw err
    }
  }

async function saveTestMeta(testId, payload) {
  try {
    if (payload.tags !== undefined) {
      let tags = payload.tags
      while (typeof tags === 'string') {
        try { tags = JSON.parse(tags) } catch { break }
      }
      payload.tags = Array(tags).flat(Infinity).map(t => String(t).trim()).filter(Boolean)
    }
    await axios.patch(`${API_BASE_URL}/api/tests/${testId}`, payload)
  } catch (err) {
    console.error("Failed to save test meta:", err)
  }
}

async function fetchTestRuns(testId) {
  if (!testId) return
  try {
    const res = await axios.get(`${API_BASE_URL}/api/tests/${testId}/test_runs`)
    // Only update if this is still the selected test
    // Prevents stale polling from overwriting runs when user switched test
    if (selectedTest.value?.id === testId) {
      testRuns.value = res.data
    }
  } catch (err) {
    console.error("Failed to fetch test runs:", err)
  }
}

  function addTest(newTest) {
    const exists = tests.value.find(t => t.id === newTest.id)
    if (!exists) {
      tests.value.push({
        id: newTest.id,
        title: newTest.title,
        status: 'NEW',
        environment: null,
        lastRun: null,
        startedAt: null,
        finishedAt: null,
        duration: null,
        retries_on_failure: 2,
        runner_mode: 'headless',
        tags: [],
        artifacts: [],
        script: { raw: null, normalized: null }
      })
    }
  }

  function setSelectedTest(test) {
    resetNormalization.value = false
    selectedTest.value = test
    refreshSingleTest(test.id)
  }

// Add this function in testStore.js
function syncTagsToTestsList(testId, newTags) {
  // Update in tests array so sidebar reflects instantly
  const index = tests.value.findIndex(t => t.id === testId)
  if (index !== -1) {
    tests.value[index] = { ...tests.value[index], tags: newTags }
  }
  // Update selectedTest too
  if (selectedTest.value?.id === testId) {
    selectedTest.value.tags = newTags
  }
}

async function refreshSingleTest(testId) {
  try {
    const res = await axios.get(`${API_BASE_URL}/api/tests/${testId}`)
    const fresh = res.data
    // Update ALL fields including user-controlled ones — this is a deliberate load
    const index = tests.value.findIndex(t => t.id === testId)
    if (index !== -1) {
      tests.value[index] = { ...tests.value[index], ...fresh }
    }
    if (selectedTest.value?.id === testId) {
      selectedTest.value = { ...selectedTest.value, ...fresh }
    }
  } catch (err) {
    console.error("Failed to refresh single test:", err)
  }
}

  function updateTestRunConfig(config) {
    testRunConfig.value = { ...testRunConfig.value, ...config }
  }

  function clearSelectedTest() {
    selectedTest.value = null
  }

  function setSearchQuery(query) {
    searchQuery.value = query
  }

  function clearSearchQuery() {
    searchQuery.value = ''
  }

 function startPolling(testId, editingRef = null) {
  stopPolling()
  vncOpened.value = false

  pollingInterval.value = setInterval(async () => {
    await refreshTestsFromBackend()
    await refreshFeaturesFromBackend()
    await fetchTestRuns(testId)

    const updatedTest = tests.value.find(t => t.id === testId)
    if (!updatedTest) return

    // REMOVED setSelectedTest — fields are updated in place above
    // This prevents sidebar re-render and focus loss

    if (!vncOpened.value && updatedTest.vnc_url) {
      vncOpened.value = true
      window.open(updatedTest.vnc_url, '_blank')
    }

    if (updatedTest.status === 'passed') {
      stopPolling()
      return
    }

    if (updatedTest.status === 'failed') {
      const traceArtifact = updatedTest.artifacts?.find(a => a.kind === 'trace')
      if (traceArtifact && traceArtifact.url) {
        stopPolling()
        return
      }
    }
  }, 3000)
}

  function stopPolling() {
    if (pollingInterval.value) {
      clearInterval(pollingInterval.value)
      pollingInterval.value = null
      runEndTime.value = new Date()
      vncOpened.value = false
    }
  }

  return {
    tests,
    features,
    selectedTest,
    searchQuery,
    runEndTime,
    testRunConfig,
    testRuns,
    resetNormalization,
    vncOpened,
    isAnyRunning,
    queuedRuns,
    refreshTestsFromBackend,
    refreshFeaturesFromBackend,
    runFeature,
    deleteFeature,
    refreshSingleTest,
    deleteTest,
    saveTestMeta,
    fetchTestRuns,
    syncTagsToTestsList,
    addTest,
    setSelectedTest,
    updateTestRunConfig,
    clearSelectedTest,
    setSearchQuery,
    clearSearchQuery,
    startPolling,
    stopPolling
  }
})