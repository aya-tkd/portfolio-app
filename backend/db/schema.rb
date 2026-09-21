# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_21_000100) do
  create_table "mst_departments", force: :cascade do |t|
    t.string "abbreviation", limit: 20
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.integer "display_order", null: false
    t.string "kana_name", limit: 100
    t.string "name", limit: 100, null: false
    t.datetime "updated_at", null: false
    t.check_constraint "abbreviation IS NULL OR length(abbreviation) <= 20", name: "mst_departments_abbreviation_length"
    t.check_constraint "active IN (0, 1)", name: "mst_departments_active_values"
    t.check_constraint "display_order >= 1", name: "mst_departments_display_order_positive"
    t.check_constraint "kana_name IS NULL OR length(kana_name) <= 100", name: "mst_departments_kana_name_length"
    t.check_constraint "length(name) <= 100", name: "mst_departments_name_length"
  end

  create_table "mst_occupations", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.integer "display_order", null: false
    t.string "name", limit: 100, null: false
    t.string "occupation_code", default: "other", null: false
    t.datetime "updated_at", null: false
    t.check_constraint "active IN (0, 1)", name: "mst_occupations_active_values"
    t.check_constraint "display_order >= 1", name: "mst_occupations_display_order_positive"
    t.check_constraint "length(name) <= 100", name: "mst_occupations_name_length"
    t.check_constraint "occupation_code IN ('physician', 'other')", name: "mst_occupations_occupation_code_values"
  end

  create_table "mst_patients", force: :cascade do |t|
    t.date "birth_date"
    t.datetime "created_at", null: false
    t.string "first_name", limit: 100, null: false
    t.string "first_name_kana", limit: 100, null: false
    t.string "last_name", limit: 100, null: false
    t.string "last_name_kana", limit: 100, null: false
    t.string "patient_number", null: false
    t.string "sex", default: "", null: false
    t.datetime "updated_at", null: false
    t.index ["patient_number"], name: "index_mst_patients_on_patient_number", unique: true
    t.check_constraint "sex IN ('', 'male', 'female', 'other')", name: "patients_sex_values"
  end

  create_table "mst_users", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.integer "department_id"
    t.string "first_name", limit: 100, null: false
    t.string "first_name_kana", limit: 100, null: false
    t.string "last_name", limit: 100, null: false
    t.string "last_name_kana", limit: 100, null: false
    t.integer "occupation_id"
    t.datetime "updated_at", null: false
    t.index ["department_id"], name: "index_mst_users_on_department_id"
    t.index ["occupation_id"], name: "index_mst_users_on_occupation_id"
    t.check_constraint "active IN (0, 1)", name: "mst_users_active_values"
  end

  create_table "trn_appointments", force: :cascade do |t|
    t.string "appointment_kind", null: false
    t.datetime "created_at", null: false
    t.integer "department_id", null: false
    t.string "doctor_name"
    t.integer "doctor_user_id"
    t.string "equipment_name"
    t.integer "parent_appointment_id"
    t.integer "patient_id", null: false
    t.integer "reception_id"
    t.datetime "scheduled_at", null: false
    t.string "status", default: "reserved", null: false
    t.datetime "updated_at", null: false
    t.index ["department_id"], name: "index_trn_appointments_on_department_id"
    t.index ["doctor_user_id"], name: "index_trn_appointments_on_doctor_user_id"
    t.index ["parent_appointment_id"], name: "index_trn_appointments_on_parent_appointment_id"
    t.index ["patient_id"], name: "index_trn_appointments_on_patient_id"
    t.index ["reception_id"], name: "index_trn_appointments_on_reception_id"
    t.index ["reception_id"], name: "one_root_per_reception", unique: true, where: "parent_appointment_id IS NULL AND reception_id IS NOT NULL"
    t.index ["scheduled_at"], name: "index_trn_appointments_on_scheduled_at"
    t.check_constraint "appointment_kind IN ('consultation','equipment')", name: "appointment_kind"
    t.check_constraint "status IN ('reserved','cancelled')", name: "appointment_status"
  end

  create_table "trn_equipment_executions", force: :cascade do |t|
    t.integer "appointment_id"
    t.datetime "cancelled_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.integer "department_id", null: false
    t.string "equipment_name", null: false
    t.integer "reception_id", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["appointment_id"], name: "index_trn_equipment_executions_on_appointment_id", unique: true
    t.index ["department_id"], name: "index_trn_equipment_executions_on_department_id"
    t.index ["reception_id"], name: "index_trn_equipment_executions_on_reception_id"
  end

  create_table "trn_receptions", force: :cascade do |t|
    t.string "business_kind", default: "consultation", null: false
    t.datetime "called_at"
    t.string "consultation_status", default: "received", null: false
    t.datetime "created_at", null: false
    t.integer "department_id", null: false
    t.string "doctor_name"
    t.integer "doctor_user_id"
    t.datetime "finished_at"
    t.integer "lock_version", default: 0, null: false
    t.datetime "paid_at"
    t.integer "patient_id", null: false
    t.datetime "received_at", null: false
    t.string "reception_number", null: false
    t.datetime "started_at"
    t.datetime "updated_at", null: false
    t.index ["department_id"], name: "index_trn_receptions_on_department_id"
    t.index ["doctor_user_id"], name: "index_trn_receptions_on_doctor_user_id"
    t.index ["patient_id"], name: "index_trn_receptions_on_patient_id"
    t.index ["received_at"], name: "index_trn_receptions_on_received_at"
    t.index ["reception_number"], name: "index_trn_receptions_on_reception_number", unique: true
    t.check_constraint "business_kind IN ('consultation','equipment')", name: "reception_kind"
    t.check_constraint "consultation_status IN ('received','called','consulting','consulted')", name: "reception_status"
  end

  add_foreign_key "mst_users", "mst_departments", column: "department_id"
  add_foreign_key "mst_users", "mst_occupations", column: "occupation_id"
  add_foreign_key "trn_appointments", "mst_departments", column: "department_id"
  add_foreign_key "trn_appointments", "mst_patients", column: "patient_id"
  add_foreign_key "trn_appointments", "mst_users", column: "doctor_user_id"
  add_foreign_key "trn_appointments", "trn_appointments", column: "parent_appointment_id"
  add_foreign_key "trn_appointments", "trn_receptions", column: "reception_id"
  add_foreign_key "trn_equipment_executions", "mst_departments", column: "department_id"
  add_foreign_key "trn_equipment_executions", "trn_appointments", column: "appointment_id"
  add_foreign_key "trn_equipment_executions", "trn_receptions", column: "reception_id"
  add_foreign_key "trn_receptions", "mst_departments", column: "department_id"
  add_foreign_key "trn_receptions", "mst_patients", column: "patient_id"
  add_foreign_key "trn_receptions", "mst_users", column: "doctor_user_id"
end
