import { test, expect } from '@playwright/test'
import { execFileSync } from 'node:child_process'

// 専用の架空患者セットを追加し、実際のVue→Rails→SQLiteを検証する。
// 既存データは消さない。batch識別子で他の受入データと混同しない。
const batch = `E2E${Date.now()}`
let data
test.beforeAll(async ({ request }) => {
  execFileSync('ruby', ['bin/rails', 'runner', `Outpatient::DemoData.call(batch: '${batch}')`], { cwd: 'backend', timeout: 60000 })
  const response = await request.get('/api/outpatients')
  expect(response.ok()).toBeTruthy()
  data = (await response.json()).rows.filter(row => row.patient_name.includes(batch))
})

test('親子展開・単一操作・完了順とDB永続化', async ({ page }) => {
  await page.goto('/outpatients')
  const target = data.find(row => row.status === 'consulting')
  const row = page.locator(`[data-row="${target.key}"]`)
  await expect(row).toBeVisible()
  await row.getByRole('button', { name: /設備行/ }).click()
  const equipment = target.equipment.find(item => item.status === 'waiting')
  const child = page.locator(`[data-equipment="${equipment.key}"]`)
  await expect(child).toBeVisible()
  await expect(row.locator('.outpatient-action button')).toHaveCount(1)
  await row.getByRole('button', { name: '診察終了' }).click()
  await expect(row).toContainText('設備待ち')
  await child.getByRole('button', { name: '実施', exact: true }).click()
  await expect(row).toContainText('会計待ち')
  await expect(row.locator('.outpatient-action button')).toHaveCount(0)
  await page.reload()
  await expect(row).toContainText('会計待ち')
  await row.getByRole('button', { name: /設備行/ }).click()
  await expect(child).toContainText('実施済')
  await row.getByRole('button', { name: /設備行/ }).click()
  await expect(child).toHaveCount(0)
})

test('診察の文言切替、検査のみ、複数条件検索、未選択', async ({ page }) => {
  await page.goto('/outpatients')
  const target = data.find(row => row.kind === 'consultation' && row.status === 'received')
  const row = page.locator(`[data-row="${target.key}"]`)
  for (const name of ['呼出', '診察開始', '診察終了']) {
    await row.getByRole('button', { name, exact: true }).click()
    await expect(page.getByRole('status')).toContainText(`${name}を記録`)
  }
  await expect(row).toContainText('会計待ち')
  const exam = data.find(item => item.kind === 'equipment' && item.reception_id)
  const examRow = page.locator(`[data-row="${exam.key}"]`)
  await examRow.getByRole('button', { name: '実施' }).click()
  await expect(examRow).toContainText('会計待ち')
  for (const checkbox of await page.getByRole('checkbox').all()) await checkbox.uncheck()
  await page.getByRole('button', { name: '検索', exact: true }).click()
  await expect(page.locator('tbody tr')).toHaveCount(0)
  await page.getByRole('checkbox', { name: '予約', exact: true }).check()
  await page.getByRole('checkbox', { name: '会計待ち', exact: true }).check()
  await page.getByLabel('診療科', { exact: true }).selectOption(String(target.department_id))
  await page.getByRole('button', { name: '検索', exact: true }).click()
  await expect(row).toBeVisible()
  await expect(page.locator('tbody tr')).not.toHaveCount(0)
})

test('別タブの更新後は古い操作を止め、再検索できる', async ({ page, context }) => {
  const target = data.find(row => row.status === 'called')
  await page.goto('/outpatients')
  const row = page.locator(`[data-row="${target.key}"]`)
  await expect(row).toBeVisible()
  const other = await context.newPage()
  await other.goto('/outpatients')
  await other.locator(`[data-row="${target.key}"]`).getByRole('button', { name: '診察開始' }).click()
  await expect(other.getByRole('status')).toContainText('診察開始を記録')
  await row.getByRole('button', { name: '診察開始' }).click()
  await expect(page.getByRole('status')).toContainText('再検索')
  await expect(row.getByRole('button', { name: '診察開始' })).toBeDisabled()
  await page.getByRole('button', { name: '検索', exact: true }).click()
  await expect(row.getByRole('button', { name: '診察終了' })).toBeEnabled()
  await other.close()
})
