require "test_helper"

class Reservation::BookTest < ActiveSupport::TestCase
  def create_slot(group:, capacity: 2, name: nil)
    ReservationSlot.create!(name: name || "#{group}枠", slot_group: group, weekdays_mask: ReservationSlot.weekdays_to_mask([1, 2, 3, 4, 5]),
      valid_from: Date.new(2026, 10, 1), valid_to: Date.new(2026, 12, 31), start_minute: 540, end_minute: 720,
      interval_minutes: 30, capacity:, display_order: 0, active: true)
  end

  test "equipment can be entered before consultation and is linked after persistence" do
    patient = Patient.create!(patient_attributes)
    department = Department.create!(department_attributes)
    occupation = Occupation.create!(occupation_attributes.merge(occupation_code: "physician"))
    doctor = User.create!(last_name: "予約", first_name: "医師", last_name_kana: "ヨヤク", first_name_kana: "イシ", department:, occupation:, active: true)
    consultation = create_slot(group: "consultation")
    equipment = create_slot(group: "equipment", name: "MRI枠")

    records = Reservation::Book.call(patient:, entries: [
      { entry_key: "equipment", reservation_slot_id: equipment.id, scheduled_at: "2026-10-05T09:30:00+09:00", department_id: department.id, parent_entry_key: "consultation" },
      { entry_key: "consultation", reservation_slot_id: consultation.id, scheduled_at: "2026-10-05T10:00:00+09:00", department_id: department.id, doctor_user_id: doctor.id }
    ])

    assert_equal %w[equipment consultation], records.map { |record| record.appointment_kind }
    equipment_record, consultation_record = records
    assert_equal consultation_record.id, equipment_record.parent_appointment_id
    assert_equal doctor.id, equipment_record.doctor_user_id
    assert_equal 1, ReservationSlotUsage.find_by!(reservation_slot: equipment, scheduled_at: equipment_record.scheduled_at).booked_count
  end

  test "capacity conflict rolls back all appointments" do
    patient = Patient.create!(patient_attributes)
    department = Department.create!(department_attributes)
    slot = create_slot(group: "consultation", capacity: 1)
    Reservation::Book.call(patient:, entries: [{ entry_key: "first", reservation_slot_id: slot.id, scheduled_at: "2026-10-05T09:00:00+09:00", department_id: department.id }])

    assert_raises(Reservation::Book::Conflict) do
      Reservation::Book.call(patient:, entries: [{ entry_key: "second", reservation_slot_id: slot.id, scheduled_at: "2026-10-05T09:00:00+09:00", department_id: department.id }])
    end
    assert_equal 1, Appointment.where(reservation_slot: slot).count
    assert_equal 1, ReservationSlotUsage.find_by!(reservation_slot: slot).booked_count
  end

  test 'different patients share capacity and a late failure rolls back an earlier consumption' do
    patient = Patient.create!(patient_attributes)
    other = Patient.create!(patient_attributes)
    department = Department.create!(department_attributes)
    full = create_slot(group: 'consultation', capacity: 1)
    free = create_slot(group: 'equipment')
    entry = { entry_key: 'full', reservation_slot_id: full.id, scheduled_at: '2026-10-05T09:00:00+09:00', department_id: department.id }
    Reservation::Book.call(patient: other, entries: [entry])
    assert_no_difference('Appointment.count') do
      assert_raises(Reservation::Book::Conflict) do
        Reservation::Book.call(patient:, entries: [entry.merge(entry_key: 'free', reservation_slot_id: free.id), entry])
      end
    end
    assert_nil ReservationSlotUsage.find_by(reservation_slot: free)
  end

  test 'cancelled reservations release capacity and malformed times fail without persistence' do
    patient = Patient.create!(patient_attributes)
    department = Department.create!(department_attributes)
    slot = create_slot(group: 'consultation', capacity: 1)
    entry = { entry_key: 'one', reservation_slot_id: slot.id, scheduled_at: '2026-10-05T09:00:00+09:00', department_id: department.id }
    Reservation::Book.call(patient:, entries: [entry]).first.update!(status: 'cancelled')
    assert_equal 1, Reservation::Book.call(patient:, entries: [entry]).length
    assert_equal 1, ReservationSlotUsage.find_by!(reservation_slot: slot).booked_count
    assert_raises(Reservation::Book::InvalidBooking) { Reservation::Book.call(patient:, entries: [entry.merge(scheduled_at: 'invalid')]) }
    assert_raises(Reservation::Book::InvalidBooking) { Reservation::Book.call(patient:, entries: [entry.merge(scheduled_at: '2026-11-31T09:00:00+09:00')]) }
    assert_raises(Reservation::Book::InvalidBooking) { Reservation::Book.call(patient:, entries: [entry.merge(scheduled_at: '2026-10-05T09:01:00+09:00')]) }
  end
end
