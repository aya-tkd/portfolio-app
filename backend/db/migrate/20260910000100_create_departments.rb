# db:migrate/db:prepareでRailsが実行する診療科マスタのDB構造の変更履歴。
# 診療科IDはSQLiteの主キーで自動採番し、名称・表示順・利用状態の業務上の最低条件もDBで守る。
class CreateDepartments < ActiveRecord::Migration[8.1]
  def change
    create_table :mst_departments do |t|
      t.string :name, null: false, limit: 100
      t.string :kana_name, limit: 100
      t.string :abbreviation, limit: 20
      t.integer :display_order, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    add_check_constraint :mst_departments, "length(name) <= 100", name: "mst_departments_name_length"
    add_check_constraint :mst_departments, "kana_name IS NULL OR length(kana_name) <= 100", name: "mst_departments_kana_name_length"
    add_check_constraint :mst_departments, "abbreviation IS NULL OR length(abbreviation) <= 20", name: "mst_departments_abbreviation_length"
    add_check_constraint :mst_departments, "display_order >= 1", name: "mst_departments_display_order_positive"
    add_check_constraint :mst_departments, "active IN (0, 1)", name: "mst_departments_active_values"
  end
end
