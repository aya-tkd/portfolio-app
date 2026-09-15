# 予約予定・来院事実・設備実施を分離する。既存マスタやローカルデータは変更しない。
class CreateOutpatientWorkflow < ActiveRecord::Migration[8.1]
  def change
    create_table :trn_receptions do |t|
      t.references :patient, null: false, foreign_key: { to_table: :mst_patients }
      t.references :department, null: false, foreign_key: { to_table: :mst_departments }
      t.string :reception_number, null: false
      t.string :business_kind, null: false, default: "consultation"
      t.string :doctor_name
      t.datetime :received_at, null: false
      t.string :consultation_status, null: false, default: "received"
      t.datetime :called_at
      t.datetime :started_at
      t.datetime :finished_at
      t.datetime :paid_at
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    add_index :trn_receptions, :reception_number, unique: true
    add_index :trn_receptions, :received_at
    add_check_constraint :trn_receptions, "business_kind IN ('consultation','equipment')", name: "reception_kind"
    add_check_constraint :trn_receptions, "consultation_status IN ('received','called','consulting','consulted')", name: "reception_status"

    create_table :trn_appointments do |t|
      t.references :patient, null: false, foreign_key: { to_table: :mst_patients }
      t.references :department, null: false, foreign_key: { to_table: :mst_departments }
      t.references :reception, foreign_key: { to_table: :trn_receptions }
      t.references :parent_appointment, foreign_key: { to_table: :trn_appointments }
      t.datetime :scheduled_at, null: false
      t.string :appointment_kind, null: false
      t.string :equipment_name
      t.string :doctor_name
      t.string :status, null: false, default: "reserved"
      t.timestamps
    end
    add_index :trn_appointments, :scheduled_at
    add_check_constraint :trn_appointments, "appointment_kind IN ('consultation','equipment')", name: "appointment_kind"
    add_check_constraint :trn_appointments, "status IN ('reserved','cancelled')", name: "appointment_status"
    # 一つの受付に複数の診察予約や独立設備予約を混在させない。
    add_index :trn_appointments, :reception_id, unique: true, where: "parent_appointment_id IS NULL AND reception_id IS NOT NULL", name: "one_root_per_reception"

    create_table :trn_equipment_executions do |t|
      t.references :reception, null: false, foreign_key: { to_table: :trn_receptions }
      t.references :appointment, foreign_key: { to_table: :trn_appointments }, index: { unique: true }
      t.references :department, null: false, foreign_key: { to_table: :mst_departments }
      t.string :equipment_name, null: false
      t.datetime :scheduled_at
      t.datetime :completed_at
      t.datetime :cancelled_at
      t.timestamps
    end
  end
end
