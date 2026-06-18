import { useTestStore } from '@/stores/testStore'
import { useDateFormatter } from './useDateFormatter'
import axios from '@/plugins/axios'
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL

export function useTestOperations(isEditing = null) {
  const testStore = useTestStore()
  const { getCurrentTimestamp } = useDateFormatter()

  const runTest = async () => {
    const { selectedTest } = testStore
    if (!selectedTest) return
    const { id, title } = selectedTest
    if (!id || !title) return

    await axios.post(
      `${API_BASE_URL}/api/tests/${selectedTest.id}/test_runs`,
      {
        environment:        selectedTest.environment,
        runner_mode:        selectedTest.runner_mode || 'headless',
        retries_on_failure: selectedTest.retries_on_failure ?? 2,
        tags:               selectedTest.tags
      }
    )
    testStore.startPolling(selectedTest.id, isEditing)
    selectedTest.lastRun = getCurrentTimestamp()
    await testStore.fetchTestRuns(selectedTest.id)
  }

  const runSelectedTest = async () => {
    const { selectedTest } = testStore
    if (!selectedTest) return
    selectedTest.status = 'RUNNING'
    const { id, title } = selectedTest
    if (!id || !title) return

    testStore.isAnyRunning = true

    try {
      await axios.post(
        `${API_BASE_URL}/api/tests/${selectedTest.id}/test_runs`,
        {
          environment:        selectedTest.environment,
          runner_mode:        selectedTest.runner_mode || 'headless',
          retries_on_failure: selectedTest.retries_on_failure ?? 2,
          tags:               selectedTest.tags
        }
      )
      testStore.startPolling(selectedTest.id, isEditing)
      selectedTest.lastRun = getCurrentTimestamp()
      await testStore.fetchTestRuns(selectedTest.id)
    } catch (err) {
      testStore.isAnyRunning = false
      if (err.response?.status === 409) {
        alert('A test run is already in progress. Please wait.')
      }
    }
  }

  return {
    runTest,
    runSelectedTest
  }
}