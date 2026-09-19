import { test, expect } from '@playwright/test'

// Issue #48: 外来一覧を閉じずにマスタ設定を開き、一覧・フォーム・一覧復帰の導線を確認する。
test('AC-01, AC-02, AC-04, AC-05, AC-06, AC-07 and AC-08 master settings workflow', async ({ page }) => {
  await page.goto('/outpatients')
  await page.getByRole('button', { name: 'マスタ設定' }).click()
  await expect(page.getByRole('dialog', { name: '外来業務：マスタ設定' })).toBeVisible()
  await expect(page.getByRole('heading', { name: '患者マスタ' })).toBeVisible()

  await page.getByRole('button', { name: '診療科マスタ' }).click()
  await expect(page.getByRole('heading', { name: '診療科マスタ' })).toBeVisible()
  await expect(page.getByRole('button', { name: '編集' })).toBeDisabled()
  await expect(page.getByRole('button', { name: /ユーザーマスタ/ })).toBeDisabled()

  await page.getByRole('button', { name: '新規' }).click()
  await expect(page.getByRole('heading', { name: '診療科登録' })).toBeVisible()
  await page.getByRole('button', { name: '閉じる' }).last().click()
  await expect(page.getByRole('heading', { name: '診療科マスタ' })).toBeVisible()

  await page.getByRole('button', { name: '閉じる' }).last().click()
  await expect(page.getByRole('button', { name: 'マスタ設定' })).toBeVisible()
})
