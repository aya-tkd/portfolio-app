import { test, expect } from '@playwright/test'

// 外来一覧の自動取得をPlaywrightの時計と架空API応答で確認し、実DBへ書き込まない。
const listResponse = () => ({
  today: '2026-09-30',
  departments: [{ id: 1, name: '内科' }, { id: 2, name: '外科' }],
  rows: [{
    key: 'reception-17', kind: 'consultation', status: 'received', reception_id: 17, version: 1,
    reception_number: '0017', patient_number: 'P-017', patient_name: '架空 太郎',
    scheduled_at: null, received_at: null, equipment: [], department_name: '内科', doctor_name: null,
    next_action: 'call',
  }],
})

async function installPageClock(page) {
  await page.clock.install({ time: new Date('2026-09-30T01:00:00.000Z') })
}

async function mockPatientSearch(page) {
  await page.route('**/api/patients**', route => route.fulfill({ json: [] }))
}

test('30秒ごとに直近の検索済み条件で再取得し、検索ボタンを右端に保つ', async ({ page }) => {
  await installPageClock(page)
  const requests = []
  await page.route('**/api/outpatients**', async route => {
    requests.push(new URL(route.request().url()))
    await route.fulfill({ json: listResponse() })
  })

  await page.goto('/outpatients')
  await expect(page.getByRole('row', { name: /架空 太郎/ })).toBeVisible()
  expect(requests).toHaveLength(1)

  await page.getByLabel('診療日').fill('2026-09-29')
  await page.getByLabel('診療科').selectOption('2')
  await page.getByRole('checkbox', { name: '受付済' }).uncheck()
  await page.getByRole('button', { name: '検索', exact: true }).click()
  await expect.poll(() => requests.length).toBe(2)
  const appliedStatuses = requests[1].searchParams.getAll('statuses[]')

  // 未検索のフォーム編集は、次の定期取得条件へ反映しない。
  await page.getByLabel('診療日').fill('2026-09-28')
  await page.getByLabel('診療科').selectOption('1')
  await page.getByRole('checkbox', { name: '受付済' }).check()
  await page.clock.fastForward(30_000)
  await expect.poll(() => requests.length).toBe(3)
  expect(requests[2].searchParams.get('date')).toBe('2026-09-29')
  expect(requests[2].searchParams.get('department_id')).toBe('2')
  expect(requests[2].searchParams.getAll('statuses[]')).toEqual(appliedStatuses)

  // デスクトップでも狭幅でも検索ボタンを右端、自動更新をその左に置く。
  for (const viewport of [{ width: 1440, height: 1000 }, { width: 780, height: 900 }]) {
    await page.setViewportSize(viewport)
    const filters = await page.locator('.outpatient-filters').boundingBox()
    const search = await page.getByRole('button', { name: '検索', exact: true }).boundingBox()
    const auto = await page.getByRole('checkbox', { name: '自動更新' }).locator('xpath=..').boundingBox()
    const actions = await page.locator('.outpatient-filter-actions').boundingBox()
    expect(auto.x + auto.width).toBeLessThan(search.x)
    expect(Math.abs(actions.x + actions.width - search.x - search.width)).toBeLessThanOrEqual(2)
    expect(Math.abs(filters.x + filters.width - search.x - search.width)).toBeLessThanOrEqual(2)
  }
})

test('共通業務ダイアログ中は停止し、閉じると定期取得を再開する', async ({ page }) => {
  await installPageClock(page)
  const requests = []
  await page.route('**/api/outpatients**', async route => {
    requests.push(route.request().url())
    await route.fulfill({ json: listResponse() })
  })
  await mockPatientSearch(page)

  await page.goto('/outpatients')
  await expect.poll(() => requests.length).toBe(1)
  await page.getByRole('button', { name: '受付', exact: true }).click()
  const dialog = page.getByRole('dialog', { name: '外来業務：受付' })
  await expect(dialog).toBeVisible()
  await expect(page.locator('.outpatient-refresh-state')).toContainText('停止（ダイアログ表示中）')
  await page.clock.fastForward(60_000)
  expect(requests).toHaveLength(1)

  await dialog.getByRole('button', { name: '閉じる', exact: true }).click()
  await expect(dialog).toHaveCount(0)
  await expect(page.locator('.outpatient-refresh-state')).toContainText('有効')
  await page.clock.fastForward(30_000)
  await expect.poll(() => requests.length).toBe(2)
})

test('非表示中は停止し、表示復帰時に直ちに再取得して周期をリセットする', async ({ page }) => {
  await installPageClock(page)
  const requests = []
  await page.route('**/api/outpatients**', async route => {
    requests.push(route.request().url())
    await route.fulfill({ json: listResponse() })
  })

  await page.goto('/outpatients')
  await expect.poll(() => requests.length).toBe(1)
  await page.evaluate(() => {
    Object.defineProperty(document, 'visibilityState', { configurable: true, value: 'hidden' })
    document.dispatchEvent(new Event('visibilitychange'))
  })
  await page.clock.fastForward(30_000)
  expect(requests).toHaveLength(1)

  const visibleRefresh = page.waitForResponse(response => response.url().includes('/api/outpatients'))
  await page.evaluate(() => {
    Object.defineProperty(document, 'visibilityState', { configurable: true, value: 'visible' })
    document.dispatchEvent(new Event('visibilitychange'))
  })
  await visibleRefresh
  await expect(page.locator('.outpatient-scroll')).toHaveAttribute('aria-busy', 'false')
  await expect.poll(() => requests.length).toBe(2)
  await page.clock.fastForward(30_000)
  await expect.poll(() => requests.length).toBe(3)
})

test('取得失敗では古い行を保ち自動更新を止め、手動検索で復旧できる', async ({ page }) => {
  await installPageClock(page)
  const requests = []
  await page.route('**/api/outpatients**', async route => {
    requests.push(route.request().url())
    if (requests.length === 2) {
      await route.fulfill({ status: 503, json: { message: '一覧を更新できませんでした。' } })
      return
    }
    await route.fulfill({ json: listResponse() })
  })

  await page.goto('/outpatients')
  const row = page.getByRole('row', { name: /架空 太郎/ })
  await expect(row).toBeVisible()
  await page.clock.fastForward(30_000)
  await expect(page.getByRole('checkbox', { name: '自動更新' })).not.toBeChecked()
  await expect(page.getByRole('checkbox', { name: '自動更新' })).toBeDisabled()
  await expect(row).toBeVisible()
  await expect(page.getByRole('status')).toContainText('一覧を更新できませんでした。')
  await page.clock.fastForward(60_000)
  expect(requests).toHaveLength(2)

  await page.getByRole('button', { name: '検索', exact: true }).click()
  await expect.poll(() => requests.length).toBe(3)
  await expect(row).toBeVisible()
  await expect(page.getByRole('checkbox', { name: '自動更新' })).not.toBeChecked()
  await expect(page.getByRole('checkbox', { name: '自動更新' })).toBeEnabled()
  await page.getByRole('checkbox', { name: '自動更新' }).check()
  await page.clock.fastForward(30_000)
  await expect.poll(() => requests.length).toBe(4)
})

test('状態変更中に周期が来ても一覧GETを重ねない', async ({ page }) => {
  await installPageClock(page)
  await page.addInitScript(() => {
    Object.defineProperty(AbortSignal, 'timeout', { configurable: true, value: () => new AbortController().signal })
  })
  const listRequests = []
  let releaseUpdate
  await page.route('**/api/outpatients**', async route => {
    listRequests.push(route.request().url())
    await route.fulfill({ json: listResponse() })
  })
  await page.route('**/api/csrf', route => route.fulfill({ json: { token: 'test-only' } }))
  await page.route('**/api/outpatients/17', async route => {
    await new Promise(resolve => { releaseUpdate = resolve })
    await route.fulfill({ json: { ...listResponse().rows[0], status: 'called', next_action: 'start' } })
  })

  await page.goto('/outpatients')
  await expect.poll(() => listRequests.length).toBe(1)
  const updateRequest = page.waitForRequest(request => request.url().endsWith('/api/outpatients/17') && request.method() === 'PATCH')
  await page.getByRole('button', { name: '呼出', exact: true }).click()
  await updateRequest
  await expect.poll(() => typeof releaseUpdate).toBe('function')
  await page.clock.fastForward(30_000)
  expect(listRequests).toHaveLength(1)

  releaseUpdate()
  await expect(page.getByRole('status')).toContainText('呼出を記録しました。')
  await page.clock.fastForward(30_000)
  await expect.poll(() => listRequests.length).toBe(2)
})
