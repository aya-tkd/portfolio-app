# db:migrate/db:prepareでRailsが実行するDB構造の変更履歴。
# 表示Noを内部IDと別に持ち、重複はDBの制約でも拒否する。
class CreatePatients < ActiveRecord::Migration[8.1]
  def change
    create_table :patients do |t|
      t.string :patient_number, null: false
      t.string :last_name, null: false, limit: 100
      t.string :first_name, null: false, limit: 100
      t.string :last_name_kana, null: false, limit: 100
      t.string :first_name_kana, null: false, limit: 100
      t.date :birth_date
      t.string :sex, null: false, default: ""
      t.timestamps
    end
    add_index :patients, :patient_number, unique: true
    add_check_constraint :patients, "sex IN ('', 'male', 'female', 'other')", name: "patients_sex_values"
  end
end
