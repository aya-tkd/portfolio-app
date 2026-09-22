# 受付登録の業務トランザクションを扱うServiceである。
# Api::ReceptionsController#create から呼ばれ、予約採用と予約なし受付をまとめて検証・保存する。
# 途中で一件でも不整合が起きた場合は例外にしてDBトランザクション全体をロールバックする。
class Reception::Register
  class InvalidTarget < StandardError; end

  def self.call(patient:, targets:)
    raise InvalidTarget, "受付対象を1件以上選択してください。" if targets.blank?

    Reception.transaction do
      targets.map { |target| register_target!(patient, target.to_h.symbolize_keys) }
    end
  end

  def self.register_target!(patient, target)
    case target.fetch(:type)
    when "appointment" then register_appointment!(patient, target)
    when "unreserved" then register_unreserved!(patient, target)
    else raise InvalidTarget, "受付対象の種類が不正です。"
    end
  end
  private_class_method :register_target!

  def self.register_appointment!(patient, target)
    appointment = Appointment.lock.includes(:child_appointments).find(target.fetch(:appointment_id))
    validate_appointment!(appointment, patient)
    doctor = appointment.appointment_kind == "consultation" ? active_physician!(target[:doctor_user_id], department: appointment.department) : nil

    reception = Reception.create!(patient: patient, department: appointment.department, business_kind: appointment.appointment_kind,
      doctor_user: doctor, doctor_name: doctor&.display_name, received_at: Time.current)
    appointment.update_columns(reception_id: reception.id, doctor_user_id: doctor&.id,
      doctor_name: doctor&.display_name || appointment.doctor_name, updated_at: Time.current)
    attach_children!(appointment, reception) if appointment.appointment_kind == "consultation"
    create_execution!(appointment, reception) if appointment.appointment_kind == "equipment"
    reception
  end
  private_class_method :register_appointment!

  def self.register_unreserved!(patient, target)
    department = Department.find(target.fetch(:department_id))
    doctor = active_physician!(target[:doctor_user_id], department: department)

    Reception.create!(patient: patient, department: department, business_kind: "consultation", doctor_user: doctor,
      doctor_name: doctor.display_name, received_at: Time.current)
  end
  private_class_method :register_unreserved!

  # ブラウザが送ったIDを信頼せず、同一トランザクション内で有効な医師ユーザーか確認する。
  # 画面のselectを経由しないPOSTでも、別診療科の医師を担当医として保存させない。
  def self.active_physician!(doctor_user_id, department:)
    raise InvalidTarget, "有効な医師ユーザーを選択してください。" if doctor_user_id.blank?

    User.active_physicians_for(department).lock.find_by(id: doctor_user_id) || raise(InvalidTarget, "選択した診療科で有効な医師ユーザーを選択してください。")
  end
  private_class_method :active_physician!

  def self.validate_appointment!(appointment, patient)
    raise InvalidTarget, "選択した予約はこの患者のものではありません。" unless appointment.patient_id == patient.id
    raise InvalidTarget, "選択した予約はすでに受付済みか、利用できません。" unless appointment.status == "reserved" && appointment.reception_id.nil? && appointment.parent_appointment_id.nil?
  end
  private_class_method :validate_appointment!

  def self.attach_children!(appointment, reception)
    children = Appointment.lock.where(parent_appointment_id: appointment.id, status: "reserved", reception_id: nil).to_a
    Appointment.where(id: children.map(&:id)).update_all(reception_id: reception.id, updated_at: Time.current)
    children.each do |child|
      child.reception_id = reception.id
      create_execution!(child, reception)
    end
  end
  private_class_method :attach_children!

  def self.create_execution!(appointment, reception)
    EquipmentExecution.create!(reception: reception, appointment: appointment, department: reception.department,
      equipment_name: appointment.equipment_name, scheduled_at: appointment.scheduled_at)
  end
  private_class_method :create_execution!
end
