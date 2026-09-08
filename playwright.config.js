import { defineConfig } from '@playwright/test'
export default defineConfig({
  testDir: './e2e', workers: 1, fullyParallel: false,
  use: { baseURL: 'http://127.0.0.1:5173', viewport: { width: 1280, height: 800 }, screenshot: 'only-on-failure' },
  outputDir: 'tmp/playwright-results',
})
