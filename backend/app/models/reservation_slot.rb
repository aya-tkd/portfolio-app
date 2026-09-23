# 予約枠マスタを永続化・検証するモデル。予約枠マスタAPIから保存され、#64の予約取得が日付と開始時刻へ展開して参照する。
# 初期診療科・医師は予約入力の初期値であり、取得済み予約を更新する責務は持たない。
class ReservationSlot < ApplicationRecord
  self.table_name = "mst_reservation_slots"

  SLOT_GROUPS = %w[consultation equipment].freeze
  WEEKDAY_BITS = { 1 => 1, 2 => 2, 3 => 4, 4 => 8, 5 => 16, 6 => 32, 7 => 64 }.freeze
  SCHEDULE_FIELDS = %w[slot_group weekdays_mask valid_from valid_to start_minute end_minute interval_minutes capacity].freeze

  attr_readonly :id
  belongs_to :default_department, class_name: "Department", optional: true
  belongs_to :default_doctor_user, class_name: "User", optional: true
  has_many :appointments, dependent: :restrict_with_exception

  validates :name, presence: { message: "入力してください。" }, length: { maximum: 100, message: "100文字以内で入力してください。" }
  validates :slot_group, inclusion: { in: SLOT_GROUPS, message: "選択肢から選んでください。" }
  validates :weekdays_mask, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 127, message: "曜日を1つ以上選択してください。" }
  validates :valid_from, :valid_to, presence: { message: "入力してください。" }
  validates :start_minute, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 1439, message: "開始時刻を確認してください。" }
  validates :end_minute, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 1440, message: "終了時刻を確認してください。" }
  validates :interval_minutes, :capacity, numericality: { only_integer: true, greater_than_or_equal_to: 1, message: "1以上の整数を入力してください。" }
  validates :display_order, numericality: { only_integer: true, greater_than_or_equal_to: 0, message: "0以上の整数を入力してください。" }
  validates :active, inclusion: { in: [true, false], message: "選択肢から選んでください。" }
  validate :valid_period_and_time_range
  validate :interval_divides_time_range
  validate :default_masters_are_active_when_slot_is_active
  validate :schedule_is_not_changed_after_booking

  # APIの曜日配列とDBのビット集合を変換する。月曜=1、日曜=7を公開契約として固定する。
  def self.weekdays_to_mask(weekdays)
    values = Array(weekdays).map { |day| Integer(day, exception: false) }
    return nil unless values.all? { |day| WEEKDAY_BITS.key?(day) } && values.uniq.length == values.length && values.any?

    values.sum { |day| WEEKDAY_BITS.fetch(day) }
  end

  def weekdays
    WEEKDAY_BITS.filter_map { |day, bit| day if (weekdays_mask.to_i & bit).positive? }
  end

  def schedule_editable?
    !appointments.exists?
  end

  private

  def valid_period_and_time_range
    errors.add(:valid_to, "開始日以降を指定してください。") if valid_from.present? && valid_to.present? && valid_from > valid_to
    errors.add(:end_time, "開始時刻より後を指定してください。") if start_minute.present? && end_minute.present? && start_minute >= end_minute
  end

  def interval_divides_time_range
    return unless start_minute.present? && end_minute.present? && interval_minutes.present? && end_minute > start_minute && interval_minutes.positive?

    errors.add(:interval_minutes, "時間帯を等分できる値を指定してください。") unless ((end_minute - start_minute) % interval_minutes).zero?
  end

  def default_masters_are_active_when_slot_is_active
    return unless active?

    if default_department_id.present? && !default_department&.active?
      errors.add(:default_department_id, "利用中の診療科を選択してください。")
    end
    return if default_doctor_user_id.blank?

    unless default_doctor_user&.active? && default_doctor_user.occupation&.active? && default_doctor_user.occupation&.physician?
      errors.add(:default_doctor_user_id, "利用中の医師を選択してください。")
      return
    end
    if default_department_id.present? && default_doctor_user.department_id.present? && default_doctor_user.department_id != default_department_id
      errors.add(:default_doctor_user_id, "初期診療科に対応する医師を選択してください。")
    end
  end

  def schedule_is_not_changed_after_booking
    return unless persisted? && !schedule_editable?

    changed = SCHEDULE_FIELDS.select { |field| will_save_change_to_attribute?(field) }
    errors.add(:base, "予約に使用された枠の曜日・期間・時間・定員は変更できません。新しい枠を登録してください。") if changed.any?
  end
end
