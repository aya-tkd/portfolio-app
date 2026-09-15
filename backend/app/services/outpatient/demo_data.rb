module Outpatient
  # ローカル受入とE2E用の架空データを追加する。既存データの消去・再初期化は行わない。
  # 同一batch/日付では追加済み患者を再利用せず処理を省略し、進捗を巻き戻さない。
  class DemoData
    def self.call(batch: Date.current.to_s)
      marker = "外来デモ#{batch}"
      return if Patient.exists?(last_name: marker)
      Reception.transaction do
        department = Department.create!(name: "外来デモ内科", display_order: 100, active: true)
        other = Department.create!(name: "外来デモ整形外科", display_order: 110, active: true)
        names = %w[一郎 二郎 三郎 四郎 五郎 六郎 七郎 八郎]
        patients = names.map { |name| Patient.create!(last_name: marker, first_name: name, last_name_kana: "デモ", first_name_kana: "タロウ", sex: "") }
        base = Time.zone.local(Date.current.year, Date.current.month, Date.current.day, 9)
        %w[consulting received called received consulted received].each_with_index do |state, index|
          reception = Reception.create!(patient: patients[index], department: index == 1 ? other : department,
            received_at: base + index * 10.minutes, consultation_status: state,
            business_kind: index == 3 ? "equipment" : "consultation", doctor_name: index == 3 ? nil : "デモ医師",
            paid_at: index == 5 ? base + 2.hours : nil)
          # 予約なし受付も一覧の対象に含める（3番目）。
          root = unless index == 2
            Appointment.create!(patient: reception.patient, department: reception.department, reception: reception,
              scheduled_at: base + index * 15.minutes, appointment_kind: reception.business_kind,
              equipment_name: index == 3 ? "CT" : nil, doctor_name: "デモ予定医")
          end
          if [0, 3, 4].include?(index)
            %w[CT MRI].first(index == 0 ? 2 : 1).each_with_index do |name, offset|
              appointment = index == 3 ? root : Appointment.create!(patient: reception.patient, department: reception.department,
                reception: reception, parent_appointment: root, scheduled_at: base + (offset + 1).hours,
                appointment_kind: "equipment", equipment_name: name)
              EquipmentExecution.create!(reception: reception, department: reception.department, appointment: appointment,
                equipment_name: name, scheduled_at: appointment.scheduled_at, completed_at: offset == 1 ? base : nil)
            end
          end
        end
        Appointment.create!(patient: patients.first, department: department, scheduled_at: base + 6.hours, appointment_kind: "consultation")
        Appointment.create!(patient: patients.last, department: department, scheduled_at: base + 7.hours, appointment_kind: "equipment", equipment_name: "MRI")
      end
    end
  end
end
