import { computed } from 'vue'

export function useTestFilter(tests, searchQuery, features) {
  const filteredTests = computed(() => {
    if (!searchQuery.value.trim()) {
      return tests.value
    }

    const query = searchQuery.value.trim().toLowerCase()
    return tests.value.filter(test => {
      const titleMatch = test.title?.toLowerCase().includes(query)
      const envMatch = test.environment?.toLowerCase().includes(query)
      const tagMatch = Array.isArray(test.tags) && test.tags.some(tag => tag?.toLowerCase().includes(query))
      return titleMatch || envMatch || tagMatch
    })
  })

  const filteredFeatures = computed(() => {
    if (!searchQuery.value.trim()) {
      return features?.value || []
    }

    const query = searchQuery.value.trim().toLowerCase()
    
    return (features?.value || []).map(feature => {
      const featureNameMatch = feature.name?.toLowerCase().includes(query)
      
      const matchingTests = (feature.tests || []).filter(test => {
        const titleMatch = test.title?.toLowerCase().includes(query)
        const envMatch = test.environment?.toLowerCase().includes(query)
        const tagMatch = Array.isArray(test.tags) && test.tags.some(tag => tag?.toLowerCase().includes(query))
        return titleMatch || envMatch || tagMatch
      })
      
      if (featureNameMatch || matchingTests.length > 0) {
        return {
          ...feature,
          tests: featureNameMatch ? feature.tests : matchingTests 
        }
      }
      
      return null
    }).filter(Boolean)
  })

  return {
    filteredTests,
    filteredFeatures
  }
}
