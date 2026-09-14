import { test, expect } from '@playwright/test'

// 患者検索画面を実ブラウザ・Rails API・SQLiteまで通して確認する受入相当テスト。
// 既存フォームで患者を作成してから検索し、選択した患者を編集・保存した後に選択状態が戻ることを検証する。
async function createSearchPatient(page, token) {
  await page.goto('/patients/new')
  await page.locator('#last_name').fill(`検索${token}`)
  await page.locator('#first_name').fill('太郎')
  await page.locator('#last_name_kana').fill('ケンサクカクニン')
  await page.locator('#first_name_kana').fill('タロウ')
  await page.getByRole('button', { name: '登録', exact: true }).click()
  await expect(page.getByRole('dialog')).not.toBeVisible()
}

test('AC-01 through AC-06 search, select, edit and retain conditions', async ({ page }) => {
  const token = String(Date.now())
  await createSearchPatient(page, token)
  await page.goto('/patients')

  await page.locator('#patient-name').fill(`検索${token} 太郎`)
  await page.getByRole('button', { name: '検索', exact: true }).click()
  await expect(page.locator('tbody tr')).toHaveCount(1)

  const row = page.locator('tbody tr').first()
  await row.click()
  await expect(row.getByRole('radio')).toBeChecked()
  await page.getByRole('button', { name: '編集', exact: true }).click()
  await expect(page.getByRole('dialog')).toBeVisible()
  await page.locator('#sex').selectOption('male')
  await page.getByRole('button', { name: '登録', exact: true }).click()
  await expect(page.getByRole('dialog')).not.toBeVisible()
  await expect(page.locator('#patient-name')).toHaveValue(`検索${token} 太郎`)
  await expect(page.locator('tbody tr')).toHaveCount(1)
  await expect(page.locator('tbody tr').first().getByRole('radio')).toBeChecked()
})

test('AC-04 bottom actions are separated and edit needs a selected row', async ({ page }) => {
  await page.goto('/patients')
  await expect(page.getByRole('button', { name: '編集', exact: true })).toBeDisabled()
  await expect(page.locator('.screen-foot button')).toHaveText(['新規', '編集', '閉じる'])
  await page.getByRole('button', { name: '新規', exact: true }).click()
  await expect(page.getByRole('dialog')).toBeVisible()
  await page.locator('#close').click()
})
