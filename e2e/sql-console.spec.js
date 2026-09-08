import { test, expect } from '@playwright/test'

test('SQL console renders results and errors without losing SQL', async ({ page }) => {
  await page.goto('/tools/sql')
  const input = page.getByLabel('SQL', { exact: true })
  await input.fill("SELECT 42 AS number, NULL AS empty_value, '<script>test</script>' AS text_value")
  await page.getByRole('button', { name: '実行', exact: true }).click()
  await expect(page.getByRole('status')).toHaveText('1行表示')
  await expect(page.locator('tbody td')).toHaveText(['42', 'NULL', '<script>test</script>'])
  await input.fill('SELECT * FROM patients WHERE 0')
  await page.getByRole('button', { name: '実行', exact: true }).click()
  await expect(page.getByRole('status')).toHaveText('0行表示')
  await input.fill('DELETE FROM patients')
  await page.getByRole('button', { name: '実行', exact: true }).click()
  await expect(page.getByRole('alert')).toContainText('読み取り専用')
  await expect(input).toHaveValue('DELETE FROM patients')
  await page.screenshot({ path: 'tmp/sql-console.png' })
})
