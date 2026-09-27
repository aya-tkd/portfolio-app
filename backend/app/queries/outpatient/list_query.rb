module Outpatient
  # Controllerから日付・診療科・進捗を受け、受付行と未受付予約行を統合する読取処理。
  # 同一受付に採用済みの予約を除外し、SQL値はActive Recordのパラメータとして渡す。
  # 取得元の異なる2種類のレコードをRowPresenterで同じ画面DTOに揃えてから、表示対象の進捗で絞る。
  class ListQuery
    STATUSES = %w[reserved received called consulting equipment_wait execution_wait billing_wait paid].freeze

    # 日付・絞り込み条件を受け、一覧に出す受付済み行と未受付予約行を返す。
    def self.call(date:, department_id: nil, statuses: STATUSES)
      raise ArgumentError unless date.to_s.match?(/\A\d{4}-\d{2}-\d{2}\z/)
      day = Date.iso8601(date.to_s)
      raise ArgumentError unless statuses.is_a?(Array) && (statuses - STATUSES).empty?
      raise ArgumentError if department_id.present? && !department_id.to_s.match?(/\A[1-9][0-9]*\z/)
      start = Time.zone.local(day.year, day.month, day.day)
      receptions = Reception.includes(:patient, :department, :appointments, :equipment_executions).where(received_at: start...start + 1.day).order(:received_at, :id)
      appointments = Appointment.includes(:patient, :department, :child_appointments).where(scheduled_at: start...start + 1.day, reception_id: nil, parent_appointment_id: nil, status: "reserved").order(:scheduled_at, :id)
      if department_id.present?
        receptions = receptions.where(department_id: department_id)
        appointments = appointments.where(department_id: department_id)
      end
      rows = receptions.map { |record| RowPresenter.reception(record) } + appointments.map { |record| RowPresenter.appointment(record) }
      rows.select { |row| statuses.include?(row[:status]) }
    end
  end
end
