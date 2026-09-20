class CreateUsers < ActiveRecord::Migration[8.1]
  # スタッフ基本情報だけを保存するマスタ。認証用の資格情報はこのテーブルに含めない。
  def change
    create_table :mst_users do |t|
      t.string :last_name, null: false, limit: 100
      t.string :first_name, null: false, limit: 100
      t.string :last_name_kana, null: false, limit: 100
      t.string :first_name_kana, null: false, limit: 100
      t.references :department, foreign_key: { to_table: :mst_departments }, null: true
      t.references :occupation, foreign_key: { to_table: :mst_occupations }, null: true
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_check_constraint :mst_users, "active IN (0, 1)", name: "mst_users_active_values"
  end
end
