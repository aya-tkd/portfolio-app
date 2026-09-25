# 予約枠・日時単位の定員消費を表すモデル。
# Reservation::Book と ReservationSlotsController#availability が利用し、予約枠全体で定員を共有する。
class ReservationSlotUsage < ApplicationRecord
  self.table_name = "trn_reservation_slot_usages"

  belongs_to :reservation_slot

  validates :scheduled_at, presence: true
  validates :booked_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
