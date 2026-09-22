# 診察・設備の予定を保存する。診察進捗や実施完了はこのモデルに混在させない。
# 親予約は同じ患者・診療日の診察予約に限定する。
class Appointment < ApplicationRecord
  self.table_name = "trn_appointments"
  belongs_to :patient
  belongs_to :department
  belongs_to :reception, optional: true
  belongs_to :doctor_user, class_name: "User", optional: true
  belongs_to :parent_appointment, class_name: "Appointment", optional: true
  has_many :child_appointments, class_name: "Appointment", foreign_key: :parent_appointment_id, dependent: :restrict_with_exception
  has_one :equipment_execution, dependent: :restrict_with_exception
  validates :scheduled_at, presence: true
  validates :appointment_kind, inclusion: { in: %w[consultation equipment] }
  validates :status, inclusion: { in: %w[reserved cancelled] }
  validates :equipment_name, presence: true, if: -> { appointment_kind == "equipment" }
  validates :equipment_name, :doctor_name, length: { maximum: 100 }
  validate :consistent_links

  private

  def consistent_links
    if parent_appointment
      valid_parent = appointment_kind == "equipment" && parent_appointment.appointment_kind == "consultation" &&
        parent_appointment.patient_id == patient_id && parent_appointment.department_id == department_id &&
        parent_appointment.scheduled_at&.to_date == scheduled_at&.to_date && parent_appointment.reception_id == reception_id
      errors.add(:parent_appointment, "患者・診療科・日付・受付が一致する診察予約を指定してください。") unless valid_parent
    end
    if reception
      errors.add(:reception, "患者・診療科が一致しません。") unless reception.patient_id == patient_id && reception.department_id == department_id
      if parent_appointment_id.nil? && reception.business_kind != appointment_kind
        errors.add(:reception, "業務が一致しません。")
      end
    end
    if persisted? && child_appointments.any? { |child| child.reception_id != reception_id }
      errors.add(:reception, "子予約と受付が一致しません。")
    end
  end
end
