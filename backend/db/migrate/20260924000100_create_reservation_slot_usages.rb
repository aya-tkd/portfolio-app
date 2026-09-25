class CreateReservationSlotUsages < ActiveRecord::Migration[8.1]
  # 予約枠ごとの日時別消費数を保持し、#64 の一括登録で定員を判定する。
  # 呼び出し元は Reservation::Book。既存の枠予約も初期値へ反映してから新規登録を受け付ける。
  def change
    create_table :trn_reservation_slot_usages do |t|
      t.references :reservation_slot, null: false, foreign_key: { to_table: :mst_reservation_slots }
      t.datetime :scheduled_at, null: false
      t.integer :booked_count, null: false, default: 0
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    add_index :trn_reservation_slot_usages, %i[reservation_slot_id scheduled_at], unique: true, name: :index_reservation_slot_usages_on_slot_and_time
    add_check_constraint :trn_reservation_slot_usages, "booked_count >= 0", name: :reservation_slot_usages_booked_count_nonnegative

    reversible do |direction|
      direction.up do
        execute <<~SQL.squish
          INSERT INTO trn_reservation_slot_usages
            (reservation_slot_id, scheduled_at, booked_count, lock_version, created_at, updated_at)
          SELECT reservation_slot_id, scheduled_at, COUNT(*), 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
          FROM trn_appointments
          WHERE reservation_slot_id IS NOT NULL AND status = 'reserved'
          GROUP BY reservation_slot_id, scheduled_at
        SQL
      end
    end
  end
end
