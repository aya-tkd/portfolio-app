module Outpatient
  # 行ボタンの操作名と画面取得時のversionを受け、許可した状態遷移だけを確定する。
  # 同じ受付の診察・設備操作を一つのトランザクション/versionで競合検出する。
  class Advance
    class Conflict < StandardError; end
    STEPS = { "call" => ["received", "called", :called_at], "start" => ["called", "consulting", :started_at], "finish" => ["consulting", "consulted", :finished_at] }.freeze

    def self.call(id:, action:, version:, equipment_id: nil)
      raise ArgumentError unless version.to_s.match?(/\A\d+\z/) && (STEPS.key?(action) || action == "complete")
      Reception.transaction do
        record = Reception.find(id)
        raise Conflict unless record.lock_version == version.to_i && !record.paid_at
        # SQLiteにも有効な条件付きUPDATEで受付の更新権を先に取る。
        changed = Reception.where(id: id, lock_version: version.to_i).update_all(lock_version: version.to_i + 1, updated_at: Time.current)
        raise Conflict unless changed == 1
        record.reload
        if action == "complete"
          item = record.equipment_executions.find(equipment_id)
          raise Conflict if item.completed_at || item.cancelled_at
          item.update!(completed_at: Time.current)
        else
          expected, target, timestamp = STEPS.fetch(action)
          raise Conflict unless record.business_kind == "consultation" && record.consultation_status == expected
          record.update!(consultation_status: target, timestamp => Time.current)
        end
        RowPresenter.reception(record.reload)
      end
    end
  end
end
