require "test_helper"

# APIを通して受付・予約・設備の集約、進捗更新、競合と異常入力を検証する。
class OutpatientsTest < ActionDispatch::IntegrationTest
  setup do
    @patient = Patient.create!(patient_attributes)
    @department = Department.create!(department_attributes)
    @reception = Reception.create!(patient: @patient, department: @department, received_at: Time.current)
    @appointment = Appointment.create!(patient: @patient, department: @department, reception: @reception, scheduled_at: Time.current, appointment_kind: "consultation")
    @equipment = EquipmentExecution.create!(reception: @reception, department: @department, equipment_name: "CT")
    get "/api/csrf"
    @headers = { "X-CSRF-Token" => response.parsed_body.fetch("token") }
  end

  test "AC01-04受付を重複させず予約なし再受診と独立設備を表示する" do
    Reception.create!(patient: @patient, department: @department, received_at: Time.current)
    Appointment.create!(patient: @patient, department: @department, scheduled_at: Time.current, appointment_kind: "equipment", equipment_name: "MRI")
    get "/api/outpatients", params: { date: Date.current.to_s }
    assert_response :success
    department_names = response.parsed_body.fetch("departments").pluck("name")
    assert_equal department_names.uniq, department_names
    rows = response.parsed_body.fetch("rows")
    assert_equal 3, rows.length
    assert_equal 2, rows.count { |row| row["reception_id"] }
    assert_equal "CT", rows.first.fetch("equipment").first.fetch("name")
    get "/api/outpatients", params: { date: Date.current.to_s, statuses: %w[reserved received], department_id: @department.id }
    assert_equal 3, response.parsed_body.fetch("rows").length
    get "/api/outpatients", params: { date: Date.yesterday.to_s }
    assert_empty response.parsed_body.fetch("rows")
  end

  test "AC06診察と設備の完了順によらず会計待ちになる" do
    %w[call start finish].each { |action| advance(action); assert_response :success }
    assert_equal "equipment_wait", response.parsed_body["status"]
    advance("complete", @equipment.id)
    assert_response :success
    assert_equal "billing_wait", response.parsed_body["status"]
    assert_nil response.parsed_body["next_action"]
  end

  test "設備を先に終えても診察終了までは会計待ちにしない" do
    advance("complete", @equipment.id)
    assert_equal "received", response.parsed_body["status"]
    %w[call start finish].each { |action| advance(action) }
    assert_equal "billing_wait", response.parsed_body["status"]
  end

  test "検査のみと設備取消の会計条件" do
    @reception.update!(business_kind: "equipment")
    advance("complete", @equipment.id)
    assert_equal "billing_wait", response.parsed_body["status"]
    @equipment.update!(completed_at: nil, cancelled_at: Time.current)
    assert_equal "execution_wait", @reception.reload.display_status
    @reception.update!(business_kind: "consultation", consultation_status: "consulted")
    assert_equal "billing_wait", @reception.reload.display_status
  end

  test "古いversionや不正遷移や他受付の設備は更新しない" do
    initial = @reception.lock_version
    advance("call")
    assert_response :success
    patch "/api/outpatients/#{@reception.id}", params: { operation: { action: "call", version: initial } }, headers: @headers, as: :json
    assert_response :conflict
    assert_equal "called", @reception.reload.consultation_status
    version = @reception.lock_version
    advance("finish")
    assert_response :conflict
    assert_equal version, @reception.reload.lock_version
    other = Reception.create!(patient: @patient, department: @department, received_at: Time.current)
    equipment = EquipmentExecution.create!(reception: other, department: @department, equipment_name: "MRI")
    advance("complete", equipment.id)
    assert_response :not_found
    assert_nil equipment.reload.completed_at
    assert_equal version, @reception.reload.lock_version
  end

  test "不正検索と不正操作を400で返す" do
    ["2026-02-30", "bad"].each do |date|
      get "/api/outpatients", params: { date: date }
      assert_response :bad_request
    end
    get "/api/outpatients", params: { statuses: "received" }
    assert_response :bad_request
    get "/api/outpatients", params: { statuses: ["anything"] }
    assert_response :bad_request
    advance("paid")
    assert_response :bad_request
  end

  test "CSRFなしと実施の再実行は保存しない" do
    patch "/api/outpatients/#{@reception.id}", params: { operation: { action: "call", version: @reception.lock_version } }, as: :json
    assert_response :forbidden
    assert_equal "received", @reception.reload.consultation_status
    advance("complete", @equipment.id)
    assert_response :success
    timestamp = @equipment.reload.completed_at
    advance("complete", @equipment.id)
    assert_response :conflict
    assert_equal timestamp, @equipment.reload.completed_at
  end

  test "検査のみ受付に複数設備を隠して保存しない" do
    @reception.update!(business_kind: "equipment")
    duplicate = EquipmentExecution.new(reception: @reception, department: @department, equipment_name: "MRI")
    assert_not duplicate.valid?
  end

  test "親子予約と設備実施は別患者や別受付を許さない" do
    other = Patient.create!(patient_attributes)
    child = Appointment.new(patient: other, department: @department, parent_appointment: @appointment,
      scheduled_at: Time.current, appointment_kind: "equipment", equipment_name: "CT")
    assert_not child.valid?
    @equipment.appointment = @appointment
    assert_not @equipment.valid?
    assert_not EquipmentExecution.new(reception: @reception, equipment_name: "CT").valid?
  end

  private

  def advance(action, equipment_id = nil)
    patch "/api/outpatients/#{@reception.id}", params: { operation: { action: action, version: @reception.reload.lock_version, equipment_id: equipment_id } }, headers: @headers, as: :json
  end
end
