<script setup >

import {
  Avatar,
  AvatarFallback,
  AvatarImage,
} from '@/components/ui/avatar'

import Input from './ui/input/Input.vue';
import {  Search } from 'lucide-vue-next';
import Button from './ui/button/Button.vue';
import Separator from './ui/separator/Separator.vue';
import { useTestStore } from '@/stores/testStore';
import { storeToRefs } from 'pinia';
import { ref } from 'vue'
import RecordTestModal from '@/components/RecordTestModal.vue'
import ImportTestModal from './ImportTestModal.vue';

const emit = defineEmits(['signout'])
const testStore = useTestStore();
const { searchQuery } = storeToRefs(testStore);
const recordModalRef = ref(null)
const importModalRef=ref(null)

const openRecordModal = () => {
  recordModalRef.value?.show()
}

const onTestCreated = async (newTest) => {
  testStore.addTest(newTest)
  await testStore.refreshTestsFromBackend()
  const created = testStore.tests.find(t => t.id === newTest.id)
  if (created) testStore.setSelectedTest(created)
  const pollScript = setInterval(async () => {
    await testStore.refreshTestsFromBackend()
    const updated = testStore.tests.find(t => t.id === newTest.id)
    if (updated?.script?.raw) {
      testStore.setSelectedTest(updated)
      clearInterval(pollScript)
    }
  }, 3000)
  setTimeout(() => clearInterval(pollScript), 10 * 60 * 1000)
}

const openImportModal=()=>{
  importModalRef.value?.show()
}

const downloadLocalSetup = () => {
  const getOS = () => {
    if (navigator.userAgentData) {
      const platform = navigator.userAgentData.platform.toLowerCase()
      if (platform.includes('win')) return 'windows'
      if (platform.includes('mac')) return 'mac'
      return 'linux'
    }
    const ua = navigator.userAgent.toLowerCase()
    if (ua.includes('win')) return 'windows'
    if (ua.includes('mac')) return 'mac'
    return 'linux'
  }

  const os = getOS()

  if (os === 'windows') {
    const script = `@echo off
echo 🚀 Setting up Playwright Regression Suite...

:: 1. Install Chocolatey if not present
echo 📦 Checking Chocolatey...
where choco >nul 2>&1
if errorlevel 1 (
  echo 📦 Installing Chocolatey...
  powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
  echo ✅ Chocolatey installed
) else (
  echo ✅ Chocolatey already installed, skipping...
)

:: 2. Install Node.js v22.22.3 if not present
echo 📦 Checking Node.js...
where node >nul 2>&1
if errorlevel 1 (
  echo 📦 Installing Node.js v22.22.3...
  choco install nodejs --version="22.22.3" -y
  echo ✅ Node.js installed
) else (
  echo ✅ Node.js already installed: && node -v
)

:: Refresh PATH
for /f "tokens=2*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH') do set "SYS_PATH=%%B"
for /f "tokens=2*" %%A in ('reg query "HKCU\Environment" /v PATH 2^>nul') do set "USR_PATH=%%B"
set "PATH=%SYS_PATH%;%USR_PATH%"

:: 3. Verify Node.js
echo 🔍 Node.js version:
node -v
if errorlevel 1 (
  echo ❌ Node not found, please restart terminal and run remaining steps manually
  pause
  exit /b 1
)

:: 4. Verify npm
echo 🔍 npm version:
npm -v

:: 5. Install Playwright if not present
echo 🎭 Checking Playwright...
npx playwright --version >nul 2>&1
if errorlevel 1 (
  echo 🎭 Installing Playwright
  npm install playwright
  npx playwright install
  echo ✅ Playwright installed
) else (
  echo ✅ Playwright already installed: && npx playwright --version
)

:: 6. Start recording
echo 🔴 Starting Playwright codegen...
echo 📁 Recorded script will be saved to: %USERPROFILE%\\Desktop\\my-test.spec.js
npx playwright codegen --output "%USERPROFILE%\\Desktop\\my-test.spec.js"

echo ✅ Setup complete! Your recorded script is on the Desktop.
pause
`
    const blob = new Blob([script], { type: 'text/plain' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = 'local-setup.bat'
    a.click()
    URL.revokeObjectURL(url)

  } else if (os === 'mac') {
    const script = `#!/bin/bash

echo "🚀 Setting up Playwright Regression Suite..."

# 1. Install Homebrew if not present
echo "📦 Checking Homebrew..."
if ! command -v brew &> /dev/null; then
  echo "📦 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "✅ Homebrew already installed: $(brew --version | head -1)"
fi

# 2. Install Node.js v22 if not present
echo "📦 Checking Node.js..."
if ! command -v node &> /dev/null; then
  echo "📦 Installing Node.js v22..."
  brew install node@22
  echo 'export PATH="/opt/homebrew/opt/node@22/bin:$PATH"' >> ~/.zprofile
  export PATH="/opt/homebrew/opt/node@22/bin:$PATH"
  echo "✅ Node.js $(node -v) installed"
else
  echo "✅ Node.js already installed: $(node -v)"
fi

# 3. Verify npm
echo "🔍 npm version: $(npm -v)"

# 4. Install Playwright if not present
echo "🎭 Checking Playwright..."
if ! npx playwright --version &> /dev/null; then
  echo "🎭 Installing Playwright"
  npm install playwright
  npx playwright install
  echo "✅ Playwright installed"
else
  echo "✅ Playwright already installed: $(npx playwright --version)"
fi

# 5. Start recording
echo "🔴 Starting Playwright codegen..."
echo "📁 Recorded script will be saved to: ~/Desktop/my-test.spec.js"
npx playwright codegen --output ~/Desktop/my-test.spec.js

echo "✅ Setup complete! Your recorded script is on the Desktop."
`
    const blob = new Blob([script], { type: 'text/x-sh' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = 'local-setup-mac.sh'
    a.click()
    URL.revokeObjectURL(url)

  } else {
    const script = `#!/bin/bash

echo "🚀 Setting up Playwright Regression Suite..."

# 1. Install Node.js v22 if not present
echo "📦 Checking Node.js..."
if ! command -v node &> /dev/null; then
  echo "📦 Installing Node.js v22..."
  curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
  sudo apt-get install -y nodejs
  echo "✅ Node.js $(node -v) installed"
else
  echo "✅ Node.js already installed: $(node -v)"
fi

# 2. Verify npm
echo "🔍 npm version: $(npm -v)"

# 3. Install Playwright if not present
echo "🎭 Checking Playwright..."
if ! npx playwright --version &> /dev/null; then
  echo "🎭 Installing Playwright"
  npm install playwright
  npx playwright install
  sudo npx playwright install-deps
  echo "✅ Playwright installed"
else
  echo "✅ Playwright already installed: $(npx playwright --version)"
fi

# 4. Start recording
echo "🔴 Starting Playwright codegen..."
echo "📁 Recorded script will be saved to: ~/Desktop/my-test.spec.js"
npx playwright codegen --output ~/Desktop/my-test.spec.js

echo "✅ Setup complete! Your recorded script is on the Desktop."
`
    const blob = new Blob([script], { type: 'text/x-sh' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = 'local-setup-linux.sh'
    a.click()
    URL.revokeObjectURL(url)
  }
}


</script>

<template>
  
    <nav class="fixed top-0 left-0 right-0 z-50 bg-background border-b border-border">
        <div class="p-2 gap-3 flex flex-col justify-start w-full items-start flex-wrap lg:flex-row lg:justify-between lg:items-center">
          <div class="p-2 flex gap-7 pt-3">
            <Avatar class="ml-2 mt-1">
              <AvatarImage src="https://github.com/shadcn.png" alt="logo" />
              <AvatarFallback>logo</AvatarFallback>
            </Avatar>

            <div class="flex flex-col gap-1">
              <h4 class="font-semibold">Playwright Regression Suite</h4>
              <div class="text-xs text-slate-500 font-semibold">
                <p>Codegen • Normalize • Replay • Debug</p>
              </div>
            </div>
          </div>
          
          <div class="mt-2 relative flex items-center w-full lg:w-5/12 px-3">
            <Search class="absolute left-6 top-1/2 -translate-y-1/2 text-gray-400 w-4 h-4" />
            <Input v-model="searchQuery" placeholder="Search by name, tag, or environment..." class="flex flex-1 pl-10 p-5 px-9 bg-[#161b26] focus:bg-gray-800" />
          </div>

          <div class="mx-auto xl:mx-0 flex sm:flex-col md:flex-row gap-2 flex-wrap lg:flex-nowrap items-center mb-2 xl:mb-0">

            <div class="w-full md:w-fit mx-auto md:mx-0 lg:mx-0 flex justify-around md:gap-5 gap-2">
            <Button class="px-3 py-5 rounded-md focus-visible:ring-0 bg-yellow-600 text-white hover:bg-yellow-700 hover:-translate-y-0.5 transition-all duration-200 whitespace-nowrap" @click="downloadLocalSetup">⚙️ Local Setup</Button>              
            <!-- <Button class="bg-red-500 px-3 py-5 rounded-md hover:bg-red-600 focus-visible:ring-0 focus-visible:outline focus-visible:outline-2 focus-visible:outline-white animate-pulse transition-all duration-200 ease-out hover:-translate-y-0.5 focus-visible:-translate-y-0.5 whitespace-nowrap" @click="openRecordModal">● Record New</Button> -->
            <!-- <RecordTestModal ref="recordModalRef" @test-created="onTestCreated" /> -->
            <Button class="px-3 py-5 rounded-md focus-visible:ring-0 focus-visible:outline focus-visible:outline-2 focus-visible:outline-white focus-visible:-translate-y-0.5    animate-pulse transition-all duration-200 ease-out hover:-translate-y-0.5 whitespace-nowrap" @click="openImportModal">📥 Import</Button>
            <ImportTestModal ref="importModalRef" />

            </div>

            <div class="w-fit mx-auto md:mx-0 lg:mx-0 mt-1 lg:mt-0 ">
            <Button class="ml-3 px-3 py-5 rounded-md focus-visible:ring-0 bg-[#1c2333] text-white hover:bg-[#2a3347] hover:-translate-y-0.5" @click="emit('signout')">🚪 Sign out</Button>
            </div>

          </div>
        </div>
     
    </nav>
    <Separator class="my-2 " />
 

</template>
