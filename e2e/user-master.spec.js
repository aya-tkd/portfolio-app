import { expect, test } from '@playwright/test'

// Issue #16: 既存のマスタ設定ダイアログから、ユーザーの検索一覧と登録フォームへ遷移できることを確認する。
test('AC-01 and AC-03 user master opens from master settings', async ({ page }) => {
  await page.goto('/outpatients')
  await page.getByRole('button', { name: 'マスタ設定' }).click()
  await page.getByRole('button', { name: 'ユーザーマスタ' }).click()
  await expect(page.getByRole('heading', { name: 'ユーザーマスタ' })).toBeVisible()
  await expect(page.locator('.user-pane__search label').filter({ hasText: 'ユーザーID' })).toBeVisible()

  await page.getByRole('button', { name: '新規', exact: true }).click()
  await expect(page.getByRole('heading', { name: 'ユーザーマスタ登録' })).toBeVisible()
  await page.getByRole('button', { name: '閉じる', exact: true }).last().click()
  await expect(page.getByRole('heading', { name: 'ユーザーマスタ' })).toBeVisible()
})
