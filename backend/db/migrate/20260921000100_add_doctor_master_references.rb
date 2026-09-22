# 受付で担当医をスタッフ基本情報へ参照できるようにする。
# 既存の氏名だけのデータは変更せず、職種は安全側のotherとして移行する。
class AddDoctorMasterReferences < ActiveRecord::Migration[8.1]
  def change
    add_column :mst_occupations, :occupation_code, :string, null: false, default: "other"
    add_check_constraint :mst_occupations, "occupation_code IN ('physician', 'other')", name: "mst_occupations_occupation_code_values"

    add_reference :trn_appointments, :doctor_user, foreign_key: { to_table: :mst_users }
    add_reference :trn_receptions, :doctor_user, foreign_key: { to_table: :mst_users }
  end
end
