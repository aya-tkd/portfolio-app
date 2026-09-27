# 患者検索から受付画面へ渡す、当日・未受付の予約候補を組み立てるQueryである。
# ReceptionsController#reception_candidates が呼び出し、DBの予約を画面専用DTOへ変換する。
# 診察予約の子である設備予約は親へ要約して返し、単独設備予約は独立した候補として返す。
class Reception::CandidatesQuery
  # 患者と診療日を受け取り、受付可能な親予約と設備要約を画面DTOとして返す。
  def self.call(patient:, date: Date.current)
    start_at = Time.zone.local(date.year, date.month, date.day)
    appointments = Appointment.includes(:department, :doctor_user, :child_appointments)
      .where(patient: patient, scheduled_at: start_at...start_at + 1.day, status: "reserved", reception_id: nil, parent_appointment_id: nil)
      .order(:scheduled_at, :id)

    appointments.map do |appointment|
      children = appointment.child_appointments.select { |item| item.status == "reserved" && item.reception_id.nil? }
      {
        id: appointment.id,
        kind: appointment.appointment_kind,
        scheduled_at: appointment.scheduled_at.iso8601,
        department_id: appointment.department_id,
        department_name: appointment.department.name,
        doctor_user_id: appointment.doctor_user_id,
        doctor_name: appointment.doctor_name,
        equipment_name: appointment.equipment_name,
        attached_equipment: children.map { |item| { id: item.id, name: item.equipment_name, scheduled_at: item.scheduled_at.iso8601 } }
      }
    end
  end
end
