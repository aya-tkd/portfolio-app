# Controllerから患者属性を受け取り、検証してmst_patientsテーブルへ保存する。
# 患者基本情報のモデルであり、予約・受付の業務ルールまで共有する宣言ではない。
# Vueの入力チェックを信用せず、API経由でも制約を守るための最終検証担当。
class Patient < ApplicationRecord
  # 業務クラス名はPatientのまま、物理テーブルの分類接頭辞だけを明示する。
  self.table_name = "mst_patients"

  NAME_FIELDS = %i[last_name first_name last_name_kana first_name_kana].freeze
  attr_readonly :id, :patient_number
  validates(*NAME_FIELDS, presence: { message: "入力してください。" }, length: { maximum: 100, message: "100文字以内で入力してください。" })
  validates :last_name_kana, :first_name_kana,
            format: { with: /\A[ァ-ヶー・ 　]+\z/, message: "全角カタカナで入力してください。" }, allow_blank: true
  validates :sex, inclusion: { in: ["", "male", "female", "other"], message: "選択肢から選んでください。" }
  validate :valid_birth_date
  before_create :set_temporary_number
  after_create :assign_patient_number

  private

  def valid_birth_date
    # 型変換後は不正な日付もnilになり得るため、「未入力」と区別できる元の値を検証する。
    raw = birth_date_before_type_cast
    return if raw.nil? || raw == ""
    parsed = raw.is_a?(Date) ? raw : Date.iso8601(raw.to_s)
    if !raw.is_a?(Date) && !raw.to_s.match?(/\A\d{4}-\d{2}-\d{2}\z/)
      errors.add(:birth_date, "有効な日付を入力してください。")
    elsif parsed > Date.current
      errors.add(:birth_date, "未来日は指定できません。")
    end
  rescue ArgumentError, TypeError
    errors.add(:birth_date, "有効な日付を入力してください。")
  end

  # RailsがINSERT前後に呼ぶ。IDはINSERT後に決まるため、一意な仮番号を先に設定する。
  # 同一トランザクション内で番号を確定するので、失敗時にはINSERTも取り消される。
  def set_temporary_number
    self.patient_number = "pending-#{SecureRandom.uuid}"
  end

  def assign_patient_number
    # 初期化だけはreadonlyを迂回する。通常の編集では番号を変更できない。
    self.class.where(id: id).update_all(patient_number: id.to_s)
    reload
  end
end
