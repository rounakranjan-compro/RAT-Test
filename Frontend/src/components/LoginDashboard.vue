<script setup>

import {
  Avatar,
  AvatarFallback,
  AvatarImage,
} from '@/components/ui/avatar'

const API = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'


function loginWithGoogle() {
  console.log('API_BASE_URL:', API)
  console.log('API_URL:', API)
  window.location.href = `${API}/auth/google_oauth2`
}
</script>

<template>
    <div class="relative flex min-h-screen w-full flex-col items-center justify-center bg-[#7c3aed] px-4 overflow-hidden">
    

    <div class="absolute top-[-10%] left-[-10%] w-96 h-96 bg-purple-400 rounded-full mix-blend-multiply filter blur-3xl opacity-40 animate-blob"></div>
    <div class="absolute top-[20%] right-[-10%] w-96 h-96 bg-pink-400 rounded-full mix-blend-multiply filter blur-3xl opacity-40 animate-blob animation-delay-2000"></div>
    <div class="absolute bottom-[-10%] left-[30%] w-96 h-96 bg-indigo-400 rounded-full mix-blend-multiply filter blur-3xl opacity-40 animate-blob animation-delay-4000"></div>

    
    <div class="absolute inset-0 overflow-hidden pointer-events-none">
      <div class="particle particle-1"></div>
      <div class="particle particle-2"></div>
      <div class="particle particle-3"></div>
      <div class="particle particle-4"></div>
      <div class="particle particle-5"></div>
    </div>
    <div class="relative z-20 flex w-full max-w-sm flex-col items-center gap-20 rounded-xl border border-border  bg-card p-10 shadow-2xl">

      <div class="flex flex-col items-center gap-2 text-center">
        <Avatar class="ml-2 mt-1">
                    <AvatarImage src="https://github.com/shadcn.png" alt="logo" />
                    <AvatarFallback>logo</AvatarFallback>
                </Avatar>
        <h1 class="text-xl font-bold tracking-tight text-foreground">Playwright Regression Suite</h1>
        <p class="text-xs text-muted-foreground">Codegen · Normalize · Replay · Debug</p>
      </div>

      <div class="flex w-full flex-col gap-3">
        <p class="text-center text-sm text-muted-foreground">Sign in to your account</p>
        <button
          @click="loginWithGoogle"
          class="relative z-10 flex w-full items-center justify-center gap-6 rounded-md border border-border bg-background py-2.5 text-sm font-semibold text-foreground transition-all hover:bg-muted hover:border-primary"
        >
          <svg class="h-4 w-4" viewBox="0 0 24 24">
            <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
            <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
            <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l3.66-2.84z"/>
            <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
          </svg>
          Continue with Google
        </button>
      </div>

      <div class="text-center text-[11px] text-muted-foreground">
        By signing in you agree to our
        <a href="#" class="text-primary hover:opacity-70">Terms &amp; Privacy</a>
        <footer class="mt-6 text-center text-xs text-white/60">
      © 2026 The Gladiators ⚔️
    </footer>
  </div>
      
    </div>
    
  </div>
</template>
