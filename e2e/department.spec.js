import { expect, test } from '@playwright/test'

async function fillDepartment(page, name = '内科') {
  await page.locator('#department-name').fill(name)
  await page.locator('#department-kana-name').fill('ナイカ')
  await page.locator('#department-abbreviation').fill('内')
  await page.locator('#department-display-order').fill('10')
}

test('AC-01/03/04 register, receive id, edit and reload department', async ({ page }) => {
  // 開発DBを使うブラウザテストでも名称の重複で保存が止まらないよう、実行ごとに架空の一意名を使う。
  const name = `内科-${Date.now()}`
  const updatedName = `総合内科-${Date.now()}`
  await page.goto('/masters/departments')
  await page.getByRole('button', { name: '新規', exact: true }).click()
  await fillDepartment(page, name)
  await page.getByRole('button', { name: '登録', exact: true }).click()
  await expect(page.getByRole('dialog')).not.toBeVisible()
  await expect(page.locator('.host-notice')).toContainText('診療科ID')
  await expect(page.locator('.host-notice')).toContainText(name)
  await page.getByRole('button', { name: '編集', exact: true }).click()
  await expect(page.locator('#department-name')).toHaveValue(name)
  await expect(page.locator('#department-id')).not.toHaveText('自動採番（保存時）')
  await page.locator('#department-name').fill(updatedName)
  await page.getByRole('button', { name: '登録', exact: true }).click()
  await expect(page.locator('.host-notice')).toContainText('更新しました')
  await page.getByRole('button', { name: '編集', exact: true }).click()
  await expect(page.locator('#department-name')).toHaveValue(updatedName)
})

test('AC-02/05 validation, footer order, focus trap and discard', async ({ page }) => {
  await page.goto('/masters/departments')
  await page.getByRole('button', { name: '新規', exact: true }).click()
  await expect(page.locator('#department-name')).toBeFocused()
  await page.keyboard.press('Shift+Tab')
  await expect(page.locator('#department-close')).toBeFocused()
  await page.keyboard.press('Tab')
  await expect(page.locator('#department-name')).toBeFocused()
  await page.getByRole('button', { name: '登録', exact: true }).click()
  await expect(page.locator('#department-name')).toHaveAttribute('aria-invalid', 'true')
  await expect(page.locator('footer button')).toHaveText(['登録', '閉じる'])
  await page.locator('#department-name').fill('未保存')
  await page.keyboard.press('Escape')
  await expect(page.getByRole('button', { name: '戻る', exact: true })).toBeFocused()
  await page.getByRole('button', { name: '中止' }).click()
  await expect(page.getByRole('dialog')).not.toBeVisible()
  await expect(page.locator('#department-new')).toBeFocused()
})
