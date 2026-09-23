require "test_helper"

# 予約枠マスタのAPI契約を確認する。フォームの全入力をPOST/PATCH/GETで往復させ、旧予約への互換も確認する。
class ReservationSlotsTest < ActionDispatch::IntegrationTest
  def write_headers
    get "/api/csrf"
    { "X-CSRF-Token" => response.parsed_body.fetch("token") }
  end

  def slot_attributes(overrides = {})
    { name: "午前内科", slot_group: "consultation", weekdays: [1, 2, 3, 4, 5], valid_from: "2026-10-01", valid_to: "2027-03-31", start_time: "09:00", end_time: "12:00", interval_minutes: 30, capacity: 5, default_department_id: nil, default_doctor_user_id: nil, display_order: 0, active: true }.merge(overrides)
  end

  def physician(department: nil)
    occupation = Occupation.create!(occupation_attributes.merge(occupation_code: "physician"))
    User.create!(last_name: "テスト", first_name: "医師", last_name_kana: "テスト", first_name_kana: "イシ", department:, occupation:, active: true)
  end

  test "AC-01 and AC-02 create update reload and return options" do
    department = Department.create!(department_attributes)
    doctor = physician(department:)
    post "/api/reservation_slots", params: { reservation_slot: slot_attributes(default_department_id: department.id, default_doctor_user_id: doctor.id) }, headers: write_headers, as: :json
    assert_response :created
    created = response.parsed_body
    assert_equal [1, 2, 3, 4, 5], created.fetch("weekdays")
    assert_equal "09:00", created.fetch("start_time")
    assert_equal "内科", created.fetch("default_department_name")
    assert_equal "テスト 医師", created.fetch("default_doctor_name")

    patch "/api/reservation_slots/#{created.fetch('id')}", params: { reservation_slot: slot_attributes(name: "午後内科", start_time: "13:00", end_time: "15:00", default_department_id: nil, default_doctor_user_id: nil, lock_version: created.fetch("lock_version")) }, headers: write_headers, as: :json
    assert_response :ok
    assert_equal "午後内科", response.parsed_body.fetch("name")
    get "/api/reservation_slots/#{created.fetch('id')}"
    assert_equal "13:00", response.parsed_body.fetch("start_time")

    get "/api/reservation_slots/options"
    assert_response :ok
    assert_equal [department.id], response.parsed_body.fetch("departments").map { |item| item.fetch("id") }
    assert_equal [doctor.id], response.parsed_body.fetch("doctor_users").map { |item| item.fetch("id") }
  end

  test "AC-03 searches conditions and rejects malformed values" do
    department = Department.create!(department_attributes)
    slot = ReservationSlot.create!(slot_attributes.slice(:name, :slot_group, :valid_from, :valid_to, :interval_minutes, :capacity, :display_order, :active).merge(weekdays_mask: 31, start_minute: 540, end_minute: 720, default_department: department))
    ReservationSlot.create!(slot_attributes(name: "MRI予約", slot_group: "equipment", active: false).slice(:name, :slot_group, :valid_from, :valid_to, :interval_minutes, :capacity, :display_order, :active).merge(weekdays_mask: 31, start_minute: 540, end_minute: 720))

    get "/api/reservation_slots", params: { keyword: "午前", slot_group: "consultation", default_department_id: department.id, active: "true", page: 1, per_page: 1 }
    assert_response :ok
    assert_equal [slot.id], response.parsed_body.fetch("items").map { |item| item.fetch("id") }
    assert_equal 1, response.parsed_body.fetch("total")

    post "/api/reservation_slots", params: { reservation_slot: slot_attributes(weekdays: [], start_time: "12:00", end_time: "09:00", interval_minutes: 40, capacity: 0) }, headers: write_headers, as: :json
    assert_response :unprocessable_content
    assert response.parsed_body.fetch("errors").key?("weekdays_mask")
    get "/api/reservation_slots", params: { active: "yes" }
    assert_response :bad_request

    post "/api/reservation_slots", params: { reservation_slot: slot_attributes(start_time: "25:00") }, headers: write_headers, as: :json
    assert_response :unprocessable_content
    assert response.parsed_body.fetch("errors").key?("start_time")
  end

  test "AC-04 and AC-05 preserve legacy appointment and reject used schedule changes" do
    patient = Patient.create!(patient_attributes)
    department = Department.create!(department_attributes)
    legacy = Appointment.create!(patient:, department:, scheduled_at: Time.zone.parse("2026-10-01 08:00"), appointment_kind: "equipment", equipment_name: "MRI")
    post "/api/reservation_slots", params: { reservation_slot: slot_attributes(default_department_id: department.id) }, headers: write_headers, as: :json
    created = response.parsed_body
    appointment = Appointment.create!(patient:, department:, scheduled_at: Time.zone.parse("2026-10-01 09:00"), appointment_kind: "consultation", reservation_slot_id: created.fetch("id"))

    patch "/api/reservation_slots/#{created.fetch('id')}", params: { reservation_slot: slot_attributes(capacity: 6, default_department_id: department.id, lock_version: created.fetch("lock_version")) }, headers: write_headers, as: :json
    assert_response :unprocessable_content
    assert response.parsed_body.fetch("errors").key?("base")
    assert_nil legacy.reload.reservation_slot_id
    assert_equal created.fetch("id"), appointment.reload.reservation_slot_id
  end

  test "AC-04 returns conflict for a stale lock version" do
    post "/api/reservation_slots", params: { reservation_slot: slot_attributes }, headers: write_headers, as: :json
    created = response.parsed_body
    ReservationSlot.find(created.fetch("id")).update!(name: "別の更新")
    patch "/api/reservation_slots/#{created.fetch('id')}", params: { reservation_slot: slot_attributes(name: "古い更新", lock_version: created.fetch("lock_version")) }, headers: write_headers, as: :json
    assert_response :conflict
  end

  test "AC-04 requires a lock version for update" do
    post "/api/reservation_slots", params: { reservation_slot: slot_attributes }, headers: write_headers, as: :json
    id = response.parsed_body.fetch("id")
    patch "/api/reservation_slots/#{id}", params: { reservation_slot: slot_attributes(name: "lockなし") }, headers: write_headers, as: :json
    assert_response :bad_request
  end
end
