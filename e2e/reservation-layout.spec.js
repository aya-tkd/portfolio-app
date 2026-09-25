import { test, expect } from '@playwright/test'

// 承認モックとの相違が再発しないよう、実Vueを架空の30枠・長い週間表で操作する。
test('weekly calendar, independent scroll panes and equipment relinking', async ({ page }) => {
  const patient = { id: 999, patient_number: 'DEMO', last_name: '予約デモ', first_name: '一郎', last_name_kana: 'ヨヤクデモ', first_name_kana: 'イチロウ', sex: '', birth_date: null }
  const slots = Array.from({ length: 30 }, (_, index) => ({ id: index + 1, name: index === 0 ? '内科診察枠' : index === 1 ? 'MRI枠' : `診察枠 ${index + 1}`, slot_group: index === 1 ? 'equipment' : 'consultation', default_department_id: 1 }))
  await page.route('**/api/patients?**', route => route.fulfill({ json: [patient] }))
  await page.route('**/api/patients', route => route.fulfill({ json: [patient] }))
  await page.route('**/api/patients/999/reservation_booking', route => route.fulfill({ json: { patient, reservation_slots: slots, departments: [{ id: 1, name: '内科' }], doctor_users: [{ id: 1, name: 'テスト 医師', department_id: 1 }], appointments: Array.from({ length: 20 }, (_, i) => ({ id: i, scheduled_at: '2026-10-06T10:00:00+09:00', reservation_slot_name: '内科診察枠', department_name: '内科' })) } }))
  await page.route('**/api/reservation_slots/*/availability?**', route => {
    const start = new URL(route.request().url()).searchParams.get('week_start')
    const times = []
    for (let day = 0; day < 5; day++) for (let row = 0; row < 24; row++) {
      const date = new Date(`${start}T09:00:00+09:00`)
      date.setTime(date.getTime() + day * 86400000 + row * 1800000)
      times.push({ scheduled_at: date.toISOString(), remaining: 5 })
    }
    return route.fulfill({ json: { times } })
  })
  await page.goto('/outpatients')
  await page.getByRole('button', { name: '予約', exact: true }).click()
  await page.getByRole('row').filter({ hasText: '予約デモ' }).click()
  await page.getByRole('dialog', { name: '外来業務：予約' }).getByRole('button', { name: '予約', exact: true }).click()
  await page.getByLabel('表示週').fill('2026-10-05')
  await page.getByLabel('内科診察枠', { exact: true }).check()
  await expect(page.getByRole('table', { name: '週間の空き時間' })).toBeVisible()
  await expect(page.locator('.week-calendar thead th')).toHaveCount(8)
  await page.locator('.slot-tree summary').filter({ hasText: '診察' }).click()
  await page.getByLabel('MRI枠', { exact: true }).check()
  await page.locator('.slot-tabs').getByRole('button', { name: 'MRI枠', exact: true }).click()
  await page.getByRole('button', { name: '2026-10-05 09:00 残5', exact: true }).click()
  await page.getByRole('button', { name: '確定', exact: true }).click()
  await page.locator('.slot-tabs').getByRole('button', { name: '内科診察枠', exact: true }).click()
  await page.getByRole('button', { name: '2026-10-05 10:00 残5', exact: true }).click()
  await page.getByLabel('担当医', { exact: true }).selectOption('1')
  await page.getByRole('button', { name: '確定', exact: true }).click()
  await page.getByRole('button', { name: '変更', exact: true }).click()
  await page.getByLabel('紐付け先診察予約').selectOption({ index: 1 })
  await expect(page.getByLabel('担当医', { exact: true })).toBeDisabled()
  await page.getByRole('button', { name: '確定', exact: true }).click()
  await expect(page.locator('.booking-link')).toContainText('内科診察枠 10:00')
  await page.locator('.slot-tree summary').filter({ hasText: '診察' }).click()
  const sizes = await page.locator('.reservation-panel').evaluateAll(panels => panels.map(panel => {
    const body = panel.querySelector('.panel-scroll')
    return { bottom: panel.getBoundingClientRect().bottom, height: panel.getBoundingClientRect().height, overflow: body.scrollHeight > body.clientHeight }
  }))
  expect(sizes[0].overflow).toBeTruthy()
  expect(sizes[1].overflow).toBeTruthy()
  expect(sizes[3].overflow).toBeTruthy()
  expect(Math.abs(sizes[0].bottom - sizes[3].bottom)).toBeLessThan(2)
  expect(Math.abs(sizes[2].height - sizes[3].height)).toBeLessThan(2)
  await page.screenshot({ path: 'tmp/reservation-reviewed.png' })
  await page.getByRole('button', { name: '登録', exact: true }).click()
  await expect(page.getByRole('heading', { name: '予約内容の確認' })).toBeVisible()
  await page.getByRole('button', { name: '戻る', exact: true }).click()
  await expect(page.locator('.booking-item')).toHaveCount(2)
})
