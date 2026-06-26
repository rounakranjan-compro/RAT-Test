<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { useRoute } from 'vue-router'
import LoginDashboard from './components/LoginDashboard.vue'
import Navbar from './components/Navbar.vue'
import Sidebar from './components/Sidebar.vue'
import HeroContent from './components/HeroContent.vue'
import { useTestStore } from '@/stores/testStore'

const API = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'
const route = useRoute()

const user = ref(null)
const loading = ref(true)

const testStore = useTestStore()
let backgroundInterval = null

function startBackgroundPolling() {
  testStore.refreshTestsFromBackend()
  backgroundInterval = setInterval(() => {
    testStore.refreshTestsFromBackend()
  }, 3000)
}

function stopBackgroundPolling() {
  clearInterval(backgroundInterval)
  backgroundInterval = null
}

onMounted(async () => {
  try {
    const res = await fetch(`${API}/api/v1/me`, {
      credentials: 'include'
    })
    if (res.ok) {
      user.value = await res.json()
      startBackgroundPolling() 
    }
  } catch {
    console.log('Not authenticated Sarthak')
  } finally {
    loading.value = false
  }
})

onUnmounted(() => {
  stopBackgroundPolling()
})

function handleLogin(userData) {
  user.value = userData
  startBackgroundPolling() 
}

async function handleSignout() {
  stopBackgroundPolling() 
  await fetch(`${API}/api/v1/sign_out`, {
    method: 'DELETE',
    credentials: 'include'
  })
  user.value = null
}
</script>

<template>
  <RouterView v-if="route.path === '/auth/callback'" />

  <div v-else-if="loading" class="min-h-screen flex items-center justify-center bg-[#0b0d12]">
    <p class="text-sm text-muted-foreground animate-pulse">Loading…</p>
  </div>

  <div v-else-if="!user" class="min-h-screen flex items-center justify-center bg-[#0b0d12]">
    <LoginDashboard @login-success="handleLogin" />
  </div>

  <template v-else>
    <header>
      <Navbar :user="user" @signout="handleSignout" />
    </header>
    <div class="p-4 pt-36 md:pt-24 lg:pt-36 xl:pt-28 overflow-y-auto z-40">
      <div class="flex flex-col items-start h-fit lg:flex-row">
        <Sidebar />
        <HeroContent />
      </div>
    </div>
    <footer class="mb-4 text-center text-xs text-white/60">
      © 2026 The Gladiators ⚔️
    </footer>
  </template>
</template>