# 職種マスタのスキーマ変更履歴。職種IDはSQLiteの主キーで自動採番する。
class CreateOccupations < ActiveRecord::Migration[8.1]
  def change
    create_table :mst_occupations do |t|
      t.string :name, null: false, limit: 100
      t.integer :display_order, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_check_constraint :mst_occupations, "length(name) <= 100", name: "mst_occupations_name_length"
    add_check_constraint :mst_occupations, "display_order >= 1", name: "mst_occupations_display_order_positive"
    add_check_constraint :mst_occupations, "active IN (0, 1)", name: "mst_occupations_active_values"
  end
end
