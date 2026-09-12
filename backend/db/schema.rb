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

ActiveRecord::Schema[8.1].define(version: 2026_09_12_000100) do
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
    t.datetime "updated_at", null: false
    t.check_constraint "active IN (0, 1)", name: "mst_occupations_active_values"
    t.check_constraint "display_order >= 1", name: "mst_occupations_display_order_positive"
    t.check_constraint "length(name) <= 100", name: "mst_occupations_name_length"
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
end
