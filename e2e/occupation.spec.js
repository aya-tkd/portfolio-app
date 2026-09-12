import { expect, test } from '@playwright/test'

test('AC-01/03/04 register edit and reload occupation', async ({ page }) => {
  await page.goto('/masters/occupations')
  await page.getByRole('button', { name: '新規', exact: true }).click()
  await page.locator('#occupation-name').fill('医師')
  await page.locator('#occupation-display-order').fill('10')
  await page.getByRole('button', { name: '登録', exact: true }).click()
  await expect(page.locator('.host-notice')).toContainText('職種ID')
  await page.getByRole('button', { name: '編集', exact: true }).click()
  await expect(page.locator('#occupation-name')).toHaveValue('医師')
  await page.locator('#occupation-name').fill('看護師')
  await page.getByRole('button', { name: '登録', exact: true }).click()
  await expect(page.locator('.host-notice')).toContainText('更新しました')
})

test('AC-02/05 validates and confirms discard', async ({ page }) => {
  await page.goto('/masters/occupations')
  await page.getByRole('button', { name: '新規', exact: true }).click()
  await expect(page.locator('#occupation-name')).toBeFocused()
  await page.getByRole('button', { name: '登録', exact: true }).click()
  await expect(page.locator('#occupation-name')).toHaveAttribute('aria-invalid', 'true')
  await page.locator('#occupation-name').fill('未保存')
  await page.keyboard.press('Escape')
  await expect(page.getByRole('button', { name: '戻る', exact: true })).toBeFocused()
  await page.getByRole('button', { name: '中止' }).click()
})
