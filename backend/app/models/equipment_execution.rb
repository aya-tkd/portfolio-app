# 受付に属する設備の実施予定・完了事実。予約とは独立し、将来の設備別一覧も同じデータを使う。
# 予約なしで追加する設備も扱えるようappointmentは任意。更新は受付をロックするServiceへ集約する。
class EquipmentExecution < ApplicationRecord
  self.table_name = "trn_equipment_executions"
  belongs_to :reception
  belongs_to :department
  belongs_to :appointment, optional: true
  validates :equipment_name, presence: true, length: { maximum: 100 }
  validate :consistent_links

  private

  # 実施予定を受付・設備予約へ結び付けるときの業務整合性を検証する。
  def consistent_links
    if reception&.business_kind == "equipment" && reception.equipment_executions.where.not(id: id).exists?
      errors.add(:reception, "検査のみの受付には設備を1件だけ指定してください。")
    end
    errors.add(:department, "受付の診療科と一致しません。") if reception && department_id != reception.department_id
    if appointment && (appointment.appointment_kind != "equipment" || appointment.reception_id != reception_id || appointment.department_id != department_id)
      errors.add(:appointment, "この受付の設備予約を指定してください。")
    end
  end
end
