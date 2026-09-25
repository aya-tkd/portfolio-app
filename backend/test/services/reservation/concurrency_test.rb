require 'test_helper'

# SQLiteの独立接続から最後の一枠を取り合う。通常のテストtransactionを外し、
# この試験が作成したIDのレコードだけをensureで片付ける。
class ReservationConcurrencyTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  test 'two independent connections cannot overbook the last seat' do
    patients = 2.times.map { Patient.create!(patient_attributes) }
    department = Department.create!(department_attributes.merge(name: '競合試験診療科'))
    slot = ReservationSlot.create!(name: '競合試験枠', slot_group: 'consultation', weekdays_mask: 127,
      valid_from: '2026-10-01', valid_to: '2026-12-31', start_minute: 540, end_minute: 600,
      interval_minutes: 30, capacity: 1, display_order: 0, active: true)
    gate = Queue.new
    threads = patients.map do |patient|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          gate.pop
          begin
            Reservation::Book.call(patient:, entries: [{ entry_key: 'one', reservation_slot_id: slot.id, scheduled_at: '2026-10-05T09:00:00+09:00', department_id: department.id }])
            :created
          rescue Reservation::Book::Conflict
            :conflict
          rescue ActiveRecord::StatementInvalid => error
            raise unless error.cause.is_a?(SQLite3::BusyException)
            :busy
          end
        end
      end
    end
    2.times { gate << true }
    results = threads.map(&:value)
    assert_equal 1, results.count(:created)
    assert_equal 1, Appointment.where(reservation_slot: slot).count
    assert_equal 1, ReservationSlotUsage.find_by!(reservation_slot: slot).booked_count
  ensure
    threads&.each(&:join)
    if slot
      Appointment.where(reservation_slot_id: slot.id).delete_all
      ReservationSlotUsage.where(reservation_slot_id: slot.id).delete_all
      slot.reload.destroy!
    end
    patients&.each(&:destroy!)
    department&.destroy!
  end
end
