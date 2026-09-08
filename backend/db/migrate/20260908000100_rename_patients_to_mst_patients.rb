# 既存の患者データ・ID・表示Noを保持して、承認済みのマスタ命名へ移行する。
# 適用済みのcreate migrationは書き換えず、rollbackでは元のテーブル名へ戻す。
class RenamePatientsToMstPatients < ActiveRecord::Migration[8.1]
  def change
    rename_table :patients, :mst_patients
  end
end
