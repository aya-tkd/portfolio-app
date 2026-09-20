import { expect, test } from '@playwright/test'

// Issue #16: 既存のマスタ設定ダイアログから、ユーザーの検索一覧と登録フォームへ遷移できることを確認する。
test('AC-01 and AC-03 user master opens from master settings', async ({ page }) => {
  await page.goto('/outpatients')
  await page.getByRole('button', { name: 'マスタ設定' }).click()
  await page.getByRole('button', { name: 'ユーザーマスタ' }).click()
  await expect(page.getByRole('heading', { name: 'ユーザーマスタ' })).toBeVisible()
  await expect(page.locator('.user-pane__search label').filter({ hasText: 'ユーザーID' })).toBeVisible()

  await page.getByRole('button', { name: '新規', exact: true }).click()
  await expect(page.getByRole('heading', { name: 'ユーザー登録' })).toBeVisible()
  await page.getByRole('button', { name: '閉じる', exact: true }).last().click()
  await expect(page.getByRole('heading', { name: 'ユーザーマスタ' })).toBeVisible()
})

test('AC-03/04/06 common master form styling, validation, save and edit', async ({ page }) => {
  await page.goto('/outpatients')
  await page.getByRole('button', { name: 'マスタ設定', exact: true }).click()
  const styles = []
  // 同じ埋め込み表示で診療科・職種・ユーザーを比較する。画像は実画面の目視確認にも用いる。
  for (const [label, file] of [['診療科マスタ', 'department'], ['職種マスタ', 'occupation'], ['ユーザーマスタ', 'user']]) {
    await page.getByRole('button', { name: label, exact: true }).click()
    await page.getByRole('button', { name: '新規', exact: true }).click()
    const form = page.locator('.master-form')
    await expect(form.locator('.form-control').first()).toBeFocused()
    styles.push(await form.evaluate(element => {
      const pick = selector => {
        const style = getComputedStyle(element.querySelector(selector))
        return [style.fontSize, style.height, style.padding, style.borderRadius, style.backgroundColor]
      }
      return { input: pick('.form-control'), head: pick('.dialog-head'), foot: pick('.dialog-foot') }
    }))
    await page.screenshot({ path: `tmp/user-master-${file}.png` })
    await form.getByRole('button', { name: '閉じる', exact: true }).click()
  }
  expect(styles[2]).toEqual(styles[0])
  expect(styles[2]).toEqual(styles[1])

  await page.getByRole('button', { name: '新規', exact: true }).click()
  const form = page.locator('.master-form')
  await form.getByRole('button', { name: '登録', exact: true }).click()
  await expect(page.locator('#user-last_name')).toHaveAttribute('aria-invalid', 'true')
  await expect(page.locator('#user-last_name')).toBeFocused()
  await expect(form.locator('.required')).toHaveCount(5)
  await page.screenshot({ path: 'tmp/user-master-errors.png' })

  const name = `架空E2E${Date.now()}`
  await page.locator('#user-last_name').fill(name)
  await page.locator('#user-first_name').fill('太郎')
  await page.locator('#user-last_name_kana').fill('カクウ')
  await page.locator('#user-first_name_kana').fill('タロウ')
  await page.locator('#user-close').click()
  await expect(form.getByRole('button', { name: '戻る', exact: true })).toBeFocused()
  await form.getByRole('button', { name: '戻る', exact: true }).click()
  await form.getByRole('button', { name: '登録', exact: true }).click()
  await expect(form).toHaveCount(0)
  await expect(page.locator('.user-pane tr.selected')).toContainText(name)
  await page.getByRole('button', { name: '編集', exact: true }).click()
  await expect(page.locator('#user-last_name')).toHaveValue(name)
  await expect(page.locator('#user-id')).not.toHaveText('自動採番（保存時）')
  await page.locator('#user-first_name').fill('次郎')
  await form.getByRole('button', { name: '登録', exact: true }).click()
  await expect(page.locator('.user-pane tr.selected')).toContainText('次郎')
  await page.getByRole('button', { name: '編集', exact: true }).click()
  await expect(page.locator('#user-first_name')).toHaveValue('次郎')
  await page.screenshot({ path: 'tmp/user-master-edit.png' })
  // 高さが限られても本文だけをスクロールし、登録・閉じるに到達できること。
  await page.setViewportSize({ width: 1024, height: 500 })
  await form.locator('.dialog-body').evaluate(element => { element.scrollTop = element.scrollHeight })
  await expect(page.locator('#user-close')).toBeInViewport()
  await page.screenshot({ path: 'tmp/user-master-short.png' })
})
