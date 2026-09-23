require "test_helper"

# 予約枠の時間帯・初期値・取得済み予約の保護を、HTTPを通さないモデル単位で確認する。
class ReservationSlotTest < ActiveSupport::TestCase
  def attributes(overrides = {})
    { name: "午前内科", slot_group: "consultation", weekdays_mask: ReservationSlot.weekdays_to_mask([1, 2, 3]), valid_from: Date.new(2026, 10, 1), valid_to: Date.new(2026, 12, 31), start_minute: 9 * 60, end_minute: 12 * 60, interval_minutes: 30, capacity: 5, display_order: 0, active: true }.merge(overrides)
  end

  test "AC-01 persists a slot and converts weekday contract" do
    slot = ReservationSlot.create!(attributes)
    assert_equal [1, 2, 3], slot.weekdays
    assert_equal 7, slot.weekdays_mask
    assert_predicate slot.id, :positive?
  end

  test "AC-02 validates an active physician and department relation" do
    department = Department.create!(department_attributes)
    physician = Occupation.create!(occupation_attributes.merge(occupation_code: "physician"))
    doctor = User.create!(last_name: "医師", first_name: "太郎", last_name_kana: "イシ", first_name_kana: "タロウ", department:, occupation: physician, active: true)
    assert ReservationSlot.new(attributes(default_department: department, default_doctor_user: doctor)).valid?

    other_department = Department.create!(department_attributes.merge(name: "外科", display_order: 20))
    invalid = ReservationSlot.new(attributes(default_department: other_department, default_doctor_user: doctor))
    assert_not invalid.valid?
    assert invalid.errors.of_kind?(:default_doctor_user_id, "初期診療科に対応する医師を選択してください。")
  end

  test "AC-03 rejects invalid time interval and capacity" do
    invalid = ReservationSlot.new(attributes(start_minute: 600, end_minute: 660, interval_minutes: 40, capacity: 0, weekdays_mask: 0))
    assert_not invalid.valid?
    assert invalid.errors[:interval_minutes].any?
    assert invalid.errors[:capacity].any?
    assert invalid.errors[:weekdays_mask].any?
  end

  test "AC-04 protects schedule fields after an appointment references the slot" do
    patient = Patient.create!(patient_attributes)
    department = Department.create!(department_attributes)
    slot = ReservationSlot.create!(attributes(default_department: department))
    Appointment.create!(patient:, department:, scheduled_at: Time.zone.parse("2026-10-01 09:00"), appointment_kind: "consultation", reservation_slot: slot)

    slot.capacity = 6
    assert_not slot.save
    assert slot.errors[:base].any?
    slot.reload
    slot.name = "午前内科（名称変更）"
    assert slot.save
  end
end
