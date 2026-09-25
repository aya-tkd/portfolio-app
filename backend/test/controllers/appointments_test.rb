require "test_helper"

class AppointmentsTest < ActionDispatch::IntegrationTest
  def csrf_headers
    get "/api/csrf"
    { "X-CSRF-Token" => response.parsed_body.fetch("token") }
  end

  test "booking API returns active slots, availability and persists a bulk reservation" do
    patient = Patient.create!(patient_attributes)
    department = Department.create!(department_attributes)
    slot = ReservationSlot.create!(name: "内科診察枠", slot_group: "consultation", weekdays_mask: ReservationSlot.weekdays_to_mask([1]),
      valid_from: Date.new(2026, 10, 1), valid_to: Date.new(2026, 12, 31), start_minute: 540, end_minute: 600,
      interval_minutes: 30, capacity: 2, display_order: 0, active: true)

    get "/api/patients/#{patient.id}/reservation_booking"
    assert_response :ok
    assert_equal [slot.id], response.parsed_body.fetch("reservation_slots").map { |item| item.fetch("id") }

    get "/api/reservation_slots/#{slot.id}/availability", params: { week_start: "2026-10-05" }
    assert_response :ok
    assert_equal 2, response.parsed_body.fetch("times").length

    post "/api/appointments/bulk", params: { reservation: { patient_id: patient.id, entries: [{ entry_key: "consultation", reservation_slot_id: slot.id, scheduled_at: "2026-10-05T09:00:00+09:00", department_id: department.id }] } }, headers: csrf_headers, as: :json
    assert_response :created
    assert_equal "consultation", response.parsed_body.fetch("appointments").first.fetch("kind")
  end
end
