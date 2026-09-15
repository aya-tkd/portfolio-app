module Outpatient
  # Query/Serviceが取得したレコードをVue用DTOへ変換する。DBへの書込は行わない。
  class RowPresenter
    def self.reception(record)
      roots = record.appointments.select { |item| item.parent_appointment_id.nil? && item.status == "reserved" }
      equipment = record.equipment_executions.reject(&:cancelled_at).sort_by { |item| [item.scheduled_at || record.received_at, item.id] }
      common(record).merge(
        key: "reception-#{record.id}", reception_id: record.id, version: record.lock_version,
        reception_number: record.reception_number, received_at: record.received_at.iso8601,
        scheduled_at: roots.first&.scheduled_at&.iso8601, kind: record.business_kind,
        doctor_name: record.doctor_name, status: record.display_status,
        next_action: record.business_kind == "consultation" && !record.paid_at ? { "received" => "call", "called" => "start", "consulting" => "finish" }[record.consultation_status] : nil,
        equipment: equipment.map { |item| { id: item.id, key: "execution-#{item.id}", name: item.equipment_name,
          scheduled_at: item.scheduled_at&.iso8601, status: item.completed_at ? "completed" : "waiting",
          next_action: !item.completed_at && !record.paid_at ? "complete" : nil } }
      )
    end

    def self.appointment(record)
      equipment = record.appointment_kind == "equipment" ? [record] : record.child_appointments.select { |item| item.status == "reserved" }
      common(record).merge(key: "appointment-#{record.id}", reception_id: nil, version: nil,
        reception_number: nil, received_at: nil, scheduled_at: record.scheduled_at.iso8601,
        kind: record.appointment_kind, doctor_name: record.doctor_name, status: "reserved", next_action: nil,
        equipment: equipment.map { |item| { id: nil, key: "appointment-#{item.id}", name: item.equipment_name,
          scheduled_at: item.scheduled_at.iso8601, status: "reserved", next_action: nil } })
    end

    def self.common(record)
      { patient_number: record.patient.patient_number, patient_name: "#{record.patient.last_name} #{record.patient.first_name}",
        department_id: record.department_id, department_name: record.department.name }
    end
    private_class_method :common
  end
end
