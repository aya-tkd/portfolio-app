# 患者予約の画面内確定内容を一括保存するサービス。
# Api::AppointmentsController#create_bulk が呼び出し、画面の追加順とDBの親子保存順を分離する。
class Reservation::Book
  class InvalidBooking < StandardError; end
  class Conflict < StandardError; end

  Plan = Struct.new(:entry_key, :slot, :scheduled_at, :department, :doctor, :parent_entry_key, keyword_init: true)

  def self.call(patient:, entries:)
    new(patient:, entries:).call
  end

  def initialize(patient:, entries:)
    @patient = patient
    @raw_entries = Array(entries)
  end

  def call
    Appointment.transaction do
      # SQLiteのSELECT FOR UPDATEは行ロックにならない。最初のSQLを更新にして
      # 書込み権を取得してからマスタ・予約数を読み、競合登録の古い残数参照を防ぐ。
      ids = raw_entries.map { |entry| positive_id(entry.to_h.symbolize_keys[:reservation_slot_id]) }.compact
      ReservationSlot.where(id: ids).update_all('lock_version = lock_version + 1')
      plans = build_plans
      validate_links!(plans)
      consume_capacity!(plans)
      persist!(plans)
    end
  end

  private

  attr_reader :patient, :raw_entries

  def build_plans
    raise InvalidBooking, "予約内容を1件以上指定してください。" if raw_entries.empty?

    keys = {}
    plans = raw_entries.map do |raw|
      entry = raw.to_h.symbolize_keys
      key = entry[:entry_key].to_s
      raise InvalidBooking, "予約内容の識別子が不正です。" if key.empty? || keys[key]

      keys[key] = true
      slot = ReservationSlot.find_by(id: positive_id(entry[:reservation_slot_id]))
      raise InvalidBooking, "予約枠を選択してください。" unless slot&.active?

      scheduled_at = parse_time(entry[:scheduled_at])
      validate_slot_schedule!(slot, scheduled_at)
      Plan.new(entry_key: key, slot:, scheduled_at:, department: resolve_department(entry[:department_id]), doctor: nil, parent_entry_key: entry[:parent_entry_key].presence)
    end
    duplicates = plans.group_by { |plan| [plan.slot.id, plan.scheduled_at] }.select { |_key, values| values.length > 1 }
    raise Conflict, "同じ予約枠・日時を重複して追加できません。" if duplicates.any?

    plans
  end

  def validate_links!(plans)
    by_key = plans.index_by(&:entry_key)
    raw_by_key = raw_entries.map { |entry| entry.to_h.symbolize_keys }.index_by { |entry| entry[:entry_key].to_s }
    plans.each do |plan|
      if plan.slot.slot_group == "consultation"
        raise InvalidBooking, "診察予約に設備の紐付けは指定できません。" if plan.parent_entry_key
        plan.doctor = resolve_doctor(raw_by_key.fetch(plan.entry_key)[:doctor_user_id], plan.department)
        next
      end

      parent = plan.parent_entry_key && by_key[plan.parent_entry_key]
      raise InvalidBooking, "紐付け先の診察予約が見つかりません。" if plan.parent_entry_key && parent.nil?
      next if parent

      plan.doctor = resolve_doctor(raw_by_key.fetch(plan.entry_key)[:doctor_user_id], plan.department)
    end

    plans.select(&:parent_entry_key).each do |plan|
      parent = by_key.fetch(plan.parent_entry_key)
      raise InvalidBooking, "設備予約は診察予約にだけ紐付けられます。" unless parent.slot.slot_group == "consultation"
      raise InvalidBooking, "設備予約と診察予約は同じ予約日にしてください。" unless parent.scheduled_at.to_date == plan.scheduled_at.to_date

      plan.department = parent.department
      plan.doctor = parent.doctor
    end
  end

  def consume_capacity!(plans)
    plans.each do |plan|
      usage = ReservationSlotUsage.lock.find_or_create_by!(reservation_slot: plan.slot, scheduled_at: plan.scheduled_at)
      reserved = Appointment.where(reservation_slot: plan.slot, scheduled_at: plan.scheduled_at, status: 'reserved')
      raise Conflict, 'この患者には同じ枠・日時の予約が登録済みです。' if reserved.exists?(patient_id: patient.id)
      count = reserved.count
      raise Conflict, "#{plan.slot.name} の#{plan.scheduled_at.strftime('%m/%d %H:%M')}は満員です。" if count >= plan.slot.capacity

      usage.update!(booked_count: count + 1)
    end
  end

  def persist!(plans)
    created = {}
    plans.select { |plan| plan.slot.slot_group == "consultation" }.each { |plan| created[plan.entry_key] = create_appointment!(plan) }
    plans.select { |plan| plan.slot.slot_group == "equipment" }.each do |plan|
      created[plan.entry_key] = create_appointment!(plan, parent: plan.parent_entry_key && created.fetch(plan.parent_entry_key))
    end
    plans.map { |plan| created.fetch(plan.entry_key) }
  end

  def create_appointment!(plan, parent: nil)
    Appointment.create!(patient:, reservation_slot: plan.slot, department: plan.department, scheduled_at: plan.scheduled_at,
      appointment_kind: plan.slot.slot_group, equipment_name: plan.slot.slot_group == "equipment" ? plan.slot.name : nil,
      doctor_user: plan.doctor, doctor_name: plan.doctor&.display_name, parent_appointment: parent, status: "reserved")
  end

  def resolve_department(value)
    Department.find_by(id: positive_id(value), active: true) || raise(InvalidBooking, "有効な診療科を選択してください。")
  end

  def resolve_doctor(value, department)
    return nil if value.blank?

    User.active_physicians_for(department).find_by(id: positive_id(value)) || raise(InvalidBooking, "選択した診療科で有効な担当医を選択してください。")
  end

  def positive_id(value)
    id = Integer(value, exception: false)
    id if id&.positive?
  end

  def parse_time(value)
    raise ArgumentError unless value.to_s.match?(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:00(?:Z|[+-]\d{2}:\d{2})\z/)
    Date.iso8601(value[0, 10])
    Time.iso8601(value).in_time_zone
  rescue ArgumentError, TypeError
    raise InvalidBooking, '予約日時を正しく指定してください。'
  end

  def validate_slot_schedule!(slot, scheduled_at)
    minute = scheduled_at.hour * 60 + scheduled_at.min
    available = slot.valid_from <= scheduled_at.to_date && scheduled_at.to_date <= slot.valid_to && slot.weekdays.include?(scheduled_at.to_date.cwday) &&
      minute >= slot.start_minute && minute < slot.end_minute && ((minute - slot.start_minute) % slot.interval_minutes).zero?
    raise InvalidBooking, "#{slot.name} の予約可能な日時を選択してください。" unless available
  end
end
