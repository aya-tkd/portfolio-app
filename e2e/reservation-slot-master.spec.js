import { expect, test } from '@playwright/test'
import { execFileSync } from 'node:child_process'

// Issue #62: 実ブラウザからVue→Rails→SQLiteまでを通し、枠の新規・編集・同条件の再表示を確認する。
// 既存のローカルデータを削除せず、実行ごとの架空名称で関連マスタを追加する。
const batch = `SlotE2E${Date.now()}`
let data

test.beforeAll(() => {
  const script = `
    department = Department.create!(name: "${batch}科", display_order: 999, active: true)
    occupation = Occupation.create!(name: "${batch}医師", display_order: 999, active: true, occupation_code: "physician")
    doctor = User.create!(last_name: "${batch}", first_name: "医師", last_name_kana: "テスト", first_name_kana: "イシ", department: department, occupation: occupation, active: true)
    inactive_department = Department.create!(name: "${batch}停止科", display_order: 1000, active: true)
    inactive_doctor = User.create!(last_name: "${batch}", first_name: "停止医師", last_name_kana: "テスト", first_name_kana: "テイシ", department: inactive_department, occupation: occupation, active: true)
    inactive_slot = ReservationSlot.create!(name: "${batch}停止初期値枠", slot_group: "consultation", weekdays_mask: 31, valid_from: Date.new(2026, 10, 1), valid_to: Date.new(2027, 3, 31), start_minute: 540, end_minute: 720, interval_minutes: 30, capacity: 1, default_department: inactive_department, default_doctor_user: inactive_doctor, display_order: 1000, active: true)
    # 既存枠を保存した後に関連マスタが停止された状態を再現する。通常更新はUserの整合性検証で拒否されるため、状態変更だけを直接行う。
    inactive_department.update_columns(active: false)
    inactive_doctor.update_columns(active: false)
    puts({ department_id: department.id, doctor_id: doctor.id, inactive_slot_id: inactive_slot.id, inactive_slot_name: inactive_slot.name }.to_json)
  `
  data = JSON.parse(execFileSync('ruby', ['bin/rails', 'runner', script], { cwd: 'backend', timeout: 60000 }).toString())
})

test('AC-01/02/06〜11 create, search, edit and retain a reservation slot', async ({ page }) => {
  const name = `${batch}午前枠`
  await page.goto('/outpatients')
  await page.getByRole('button', { name: 'マスタ設定', exact: true }).click()
  await page.getByRole('button', { name: '予約枠マスタ', exact: true }).click()
  await expect(page.getByRole('heading', { name: '予約枠マスタ' })).toBeVisible()
  await expect(page.getByRole('button', { name: '編集', exact: true })).toBeDisabled()

  await page.getByRole('button', { name: '新規', exact: true }).click()
  await expect(page.locator('#reservation-slot-name')).toBeFocused()
  await page.locator('#reservation-slot-name').fill(name)
  await page.locator('#reservation-slot-valid-from').fill('2026-10-01')
  await page.locator('#reservation-slot-valid-to').fill('2027-03-31')
  await page.locator('#reservation-slot-start').fill('09:00')
  await page.locator('#reservation-slot-end').fill('12:00')
  await page.locator('#reservation-slot-interval').fill('30')
  await page.locator('#reservation-slot-capacity').fill('5')
  await page.locator('#reservation-slot-department').selectOption(String(data.department_id))
  await page.locator('#reservation-slot-doctor').selectOption(String(data.doctor_id))
  await page.getByRole('button', { name: '登録', exact: true }).click()

  const row = page.locator('.reservation-slot-pane tr.selected')
  await expect(row).toContainText(name)
  await expect(row).toContainText(`${batch}科`)
  await expect(row).toContainText(`${batch} 医師`)
  await page.getByRole('button', { name: '編集', exact: true }).click()
  await expect(page.locator('#reservation-slot-name')).toHaveValue(name)
  await expect(page.locator('#reservation-slot-doctor option:checked')).toHaveText(`${batch} 医師`)
  await page.locator('#reservation-slot-capacity').fill('7')
  await page.getByRole('button', { name: '登録', exact: true }).click()
  await expect(page.locator('.reservation-slot-pane tr.selected')).toContainText('7人')

  await page.locator('.reservation-slot-pane__search input').fill(name)
  await page.locator('.reservation-slot-pane__search button').click()
  await expect(page.locator('.reservation-slot-pane tbody tr')).toHaveCount(1)
  await page.screenshot({ path: 'tmp/reservation-slot-master.png' })
})

test('AC-03/10 rejects an invalid interval and preserves form input', async ({ page }) => {
  await page.goto('/outpatients')
  await page.getByRole('button', { name: 'マスタ設定', exact: true }).click()
  await page.getByRole('button', { name: '予約枠マスタ', exact: true }).click()
  await page.getByRole('button', { name: '新規', exact: true }).click()
  await page.locator('#reservation-slot-name').fill(`${batch}不正枠`)
  await page.locator('#reservation-slot-valid-from').fill('2026-10-01')
  await page.locator('#reservation-slot-valid-to').fill('2027-03-31')
  await page.locator('#reservation-slot-start').fill('09:00')
  await page.locator('#reservation-slot-end').fill('10:00')
  await page.locator('#reservation-slot-interval').fill('40')
  await page.getByRole('button', { name: '登録', exact: true }).click()
  await expect(page.locator('#reservation-slot-interval')).toHaveAttribute('aria-invalid', 'true')
  await expect(page.locator('#reservation-slot-name')).toHaveValue(`${batch}不正枠`)
  await page.locator('#reservation-slot-interval').fill('30')
  await page.locator('#reservation-slot-start').fill('25:00')
  await page.getByRole('button', { name: '登録', exact: true }).click()
  await expect(page.locator('#reservation-slot-start')).toHaveAttribute('aria-invalid', 'true')
})

test('AC-06 confirms discard on Escape and completes the selected left-nav transition', async ({ page }) => {
  await page.goto('/outpatients')
  await page.getByRole('button', { name: 'マスタ設定', exact: true }).click()
  await page.getByRole('button', { name: '予約枠マスタ', exact: true }).click()
  await page.getByRole('button', { name: '新規', exact: true }).click()
  await page.locator('#reservation-slot-name').fill(`${batch}未保存`)

  await page.keyboard.press('Escape')
  const form = page.locator('.reservation-slot-form')
  await expect(form.getByRole('button', { name: '戻る', exact: true })).toBeFocused()
  await form.getByRole('button', { name: '戻る', exact: true }).click()
  await expect(page.locator('#reservation-slot-name')).toHaveValue(`${batch}未保存`)

  await page.getByRole('button', { name: '患者マスタ', exact: true }).click()
  await expect(form.getByRole('button', { name: '戻る', exact: true })).toBeFocused()
  await form.getByRole('button', { name: '中止', exact: true }).click()
  await expect(page.getByRole('heading', { name: '患者マスタ' })).toBeVisible()
})

test('AC-02 displays inactive saved defaults instead of silently clearing them', async ({ page }) => {
  await page.goto('/outpatients')
  await page.getByRole('button', { name: 'マスタ設定', exact: true }).click()
  await page.getByRole('button', { name: '予約枠マスタ', exact: true }).click()
  await page.locator('.reservation-slot-pane__search input').fill(data.inactive_slot_name)
  await page.locator('.reservation-slot-pane__search button').click()
  const row = page.locator('.reservation-slot-pane tbody tr')
  await expect(row).toHaveCount(1)
  await row.click()
  await page.getByRole('button', { name: '編集', exact: true }).click()
  await expect(page.locator('#reservation-slot-department option:checked')).toHaveText(`停止中: ${batch}停止科`)
  await expect(page.locator('#reservation-slot-doctor option:checked')).toHaveText(`停止中: ${batch} 停止医師`)
})
