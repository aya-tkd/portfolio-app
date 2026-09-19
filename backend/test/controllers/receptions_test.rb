require "test_helper"

# 受付候補の取得と、予約採用・予約なし受付をまとめて保存するAPIを検証する。
# 一部の登録が失敗した場合に、先行した受付も残らないことを特に確認する。
class ReceptionsTest < ActionDispatch::IntegrationTest
  setup do
    @patient = Patient.create!(patient_attributes)
    @department = Department.create!(department_attributes)
    @other_department = Department.create!(department_attributes.merge(name: "整形外科", display_order: 20))
    scheduled_at = Time.zone.now.change(hour: 10, min: 0)
    @consultation = Appointment.create!(patient: @patient, department: @department, scheduled_at: scheduled_at,
      appointment_kind: "consultation", doctor_name: nil)
    @attached_equipment = Appointment.create!(patient: @patient, department: @department, parent_appointment: @consultation,
      scheduled_at: scheduled_at + 1.hour, appointment_kind: "equipment", equipment_name: "CT")
    @standalone_equipment = Appointment.create!(patient: @patient, department: @other_department, scheduled_at: scheduled_at + 2.hours,
      appointment_kind: "equipment", equipment_name: "MRI")
    get "/api/csrf"
    @headers = { "X-CSRF-Token" => response.parsed_body.fetch("token") }
  end

  test "候補は未受付の親予約だけを返し、子の設備は診察予約へ要約する" do
    get "/api/patients/#{@patient.id}/reception_candidates"

    assert_response :success
    candidates = response.parsed_body.fetch("appointments")
    assert_equal [@consultation.id, @standalone_equipment.id], candidates.map { |item| item.fetch("id") }
    assert_equal "CT", candidates.first.fetch("attached_equipment").first.fetch("name")
  end

  test "複数予約と予約なし受付を一括で登録し、設備実施を作成する" do
    post "/api/receptions", params: { reception: { patient_id: @patient.id, targets: [
      { type: "appointment", appointment_id: @consultation.id, doctor_name: "テスト医師" },
      { type: "appointment", appointment_id: @standalone_equipment.id },
      { type: "unreserved", department_id: @other_department.id, doctor_name: "別の医師" }
    ] } }, headers: @headers, as: :json

    assert_response :created
    assert_equal 3, response.parsed_body.fetch("receptions").length
    assert_equal 3, Reception.count
    assert_equal "テスト医師", @consultation.reload.doctor_name
    assert @consultation.reception_id
    assert_equal @consultation.reception_id, @attached_equipment.reload.reception_id
    assert_equal 2, EquipmentExecution.count, EquipmentExecution.all.map { |item| [item.appointment_id, item.equipment_name] }.inspect
    assert_equal "equipment", @standalone_equipment.reload.reception.business_kind
  end

  test "同じ予約を重複採用すると全件をロールバックする" do
    post "/api/receptions", params: { reception: { patient_id: @patient.id, targets: [
      { type: "appointment", appointment_id: @consultation.id, doctor_name: "テスト医師" },
      { type: "appointment", appointment_id: @consultation.id, doctor_name: "テスト医師" }
    ] } }, headers: @headers, as: :json

    assert_response :unprocessable_content
    assert_equal 0, Reception.count
    assert_nil @consultation.reload.reception_id
    assert_nil @attached_equipment.reload.reception_id
    assert_equal 0, EquipmentExecution.count
  end
end
