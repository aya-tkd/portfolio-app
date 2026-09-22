import { expect, test } from '@playwright/test'
import { execFileSync } from 'node:child_process'

// Issue #56: 画面が表示する候補と保存時の担当医IDを、Vue → Rails → SQLiteの経路で確認する。
// 識別子付きの架空データだけを追加し、既存データを削除・再初期化しない。
const batch = `ReceptionE2E${Date.now()}`
let data

test.beforeAll(() => {
  const script = `
    department = Department.create!(name: "${batch}診療科", display_order: 999, active: true)
    occupation = Occupation.create!(name: "${batch}医師", display_order: 999, active: true, occupation_code: "physician")
    doctor = User.create!(last_name: "${batch}", first_name: "医師", last_name_kana: "テスト", first_name_kana: "イシ", department: department, occupation: occupation, active: true)
    patient = Patient.create!(last_name: "${batch}", first_name: "患者", last_name_kana: "テスト", first_name_kana: "カンジャ", sex: "")
    appointment = Appointment.create!(patient: patient, department: department, scheduled_at: Time.zone.now.change(hour: 10, min: 0), appointment_kind: "consultation", doctor_name: "旧入力医")
    puts({ patient_id: patient.id, doctor_id: doctor.id, appointment_id: appointment.id }.to_json)
  `
  data = JSON.parse(execFileSync('ruby', ['bin/rails', 'runner', script], { cwd: 'backend', timeout: 60000 }).toString())
})

test('担当医候補を選択し、手入力履歴を置き換えて受付へ保存する', async ({ page }) => {
  await page.goto(`/receptions/new?patient_id=${data.patient_id}`)
  await expect(page.getByText('予約時の入力：旧入力医（選び直してください）')).toBeVisible()
  const doctorSelect = page.locator('.doctor-select select')
  await expect(doctorSelect).toBeDisabled()
  await page.getByRole('checkbox').first().check()
  await expect(doctorSelect).toBeEnabled()
  await expect(doctorSelect.locator(`option[value="${data.doctor_id}"]`)).toHaveText(`${batch} 医師`)
  await expect(page.locator('.reception-panel__head .btn')).toHaveCount(0)
  await expect(page.locator('.panel-note--with-action .btn')).toHaveText('行を追加')
  await page.getByRole('button', { name: '行を追加', exact: true }).click()
  await expect(page.locator('.unreserved-grid-header')).toBeVisible()
  await expect(page.locator('.unreserved-grid-header > span')).toHaveCount(3)
  await page.getByRole('button', { name: 'この行を削除' }).click()
  await doctorSelect.selectOption(String(data.doctor_id))
  await page.getByRole('button', { name: '受付', exact: true }).click()
  await expect(page.getByRole('heading', { name: '受付登録が完了しました' })).toBeVisible()

  const persisted = JSON.parse(execFileSync('ruby', ['bin/rails', 'runner', `appointment = Appointment.find(${data.appointment_id}); puts({ doctor_user_id: appointment.doctor_user_id, doctor_name: appointment.doctor_name, reception_doctor_user_id: appointment.reception.doctor_user_id }.to_json)`], { cwd: 'backend', timeout: 60000 }).toString())
  expect(persisted).toEqual({ doctor_user_id: data.doctor_id, doctor_name: `${batch} 医師`, reception_doctor_user_id: data.doctor_id })
})
