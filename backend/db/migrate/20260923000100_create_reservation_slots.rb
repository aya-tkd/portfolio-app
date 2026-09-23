# 予約取得で参照する繰り返し枠を追加する。既存の枠なし予約は変更せず、参照列をNULL許容で追加する。
class CreateReservationSlots < ActiveRecord::Migration[8.1]
  def change
    create_table :mst_reservation_slots do |t|
      t.string :name, null: false, limit: 100
      t.string :slot_group, null: false
      t.integer :weekdays_mask, null: false
      t.date :valid_from, null: false
      t.date :valid_to, null: false
      t.integer :start_minute, null: false
      t.integer :end_minute, null: false
      t.integer :interval_minutes, null: false
      t.integer :capacity, null: false
      t.references :default_department, foreign_key: { to_table: :mst_departments }
      t.references :default_doctor_user, foreign_key: { to_table: :mst_users }
      t.integer :display_order, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    add_index :mst_reservation_slots, %i[display_order id]
    add_check_constraint :mst_reservation_slots, "slot_group IN ('consultation', 'equipment')", name: "mst_reservation_slots_slot_group_values"
    add_check_constraint :mst_reservation_slots, "weekdays_mask BETWEEN 1 AND 127", name: "mst_reservation_slots_weekdays_mask_range"
    add_check_constraint :mst_reservation_slots, "valid_from <= valid_to", name: "mst_reservation_slots_valid_period"
    add_check_constraint :mst_reservation_slots, "start_minute BETWEEN 0 AND 1439", name: "mst_reservation_slots_start_minute_range"
    add_check_constraint :mst_reservation_slots, "end_minute BETWEEN 1 AND 1440 AND start_minute < end_minute", name: "mst_reservation_slots_end_minute_range"
    add_check_constraint :mst_reservation_slots, "interval_minutes >= 1", name: "mst_reservation_slots_interval_positive"
    add_check_constraint :mst_reservation_slots, "capacity >= 1", name: "mst_reservation_slots_capacity_positive"
    add_check_constraint :mst_reservation_slots, "display_order >= 0", name: "mst_reservation_slots_display_order_nonnegative"
    add_check_constraint :mst_reservation_slots, "active IN (0, 1)", name: "mst_reservation_slots_active_values"

    add_reference :trn_appointments, :reservation_slot, foreign_key: { to_table: :mst_reservation_slots }
  end
end
