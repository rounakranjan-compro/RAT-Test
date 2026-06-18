const { defineConfig, devices } = require('@playwright/test');
const retries = Number(process.env.PW_RETRIES);
const runId = process.env.TEST_RUN_ID || new Date().toISOString().replace(/[:.]/g, '-');
const attempt = process.env.RUN_ATTEMPT || Date.now().toString() // ↓ ADDED

module.exports = defineConfig({
  testDir: './tests',
  fullyParallel: false,
  workers: 1,
  forbidOnly: !!process.env.CI,
  retries: Number.isNaN(retries) ? 2 : retries,
  timeout: 120000,
  globalTimeout: 300000,
  outputDir: `artifacts/run-${runId}/attempt-${attempt}`, 
  use: {
    headless: true,
    launchOptions: {
      args: [
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-dev-shm-usage',
      ],
    },
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    trace: 'retain-on-failure',
  },
  reporter: [
    ['html'],
    ['json', { outputFile: `artifacts/run-${runId}/attempt-${attempt}/result.json` }] // ↓ CHANGED
  ],
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    }
  ],
});