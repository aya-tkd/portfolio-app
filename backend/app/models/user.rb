# 架空スタッフの基本情報を永続化するモデル。UsersControllerから受け、診療科・職種との関連を検証してmst_usersへ保存する。
# ログイン、パスワード、認可ルールは所有せず、スタッフ情報と認証アカウントを分離する。
class User < ApplicationRecord
  self.table_name = "mst_users"

  attr_readonly :id
  belongs_to :department, optional: true
  belongs_to :occupation, optional: true
  has_many :doctor_appointments, class_name: "Appointment", foreign_key: :doctor_user_id, dependent: :restrict_with_exception
  has_many :doctor_receptions, class_name: "Reception", foreign_key: :doctor_user_id, dependent: :restrict_with_exception

  NAME_FIELDS = %i[last_name first_name last_name_kana first_name_kana].freeze
  validates(*NAME_FIELDS, presence: { message: "入力してください。" }, length: { maximum: 100, message: "100文字以内で入力してください。" })
  validates :active, inclusion: { in: [true, false], message: "選択肢から選んでください。" }
  validate :selected_masters_are_active

  # 一覧画面から渡された条件だけをANDで適用する。IDは完全一致、氏名・カナは空白を無視した部分一致にする。
  def self.search(user_id: nil, name: nil, department_id: nil, occupation_id: nil)
    users = includes(:department, :occupation).order(:id)
    users = users.where(id: user_id) if user_id.present?
    if name.present?
      normalized = name.gsub(/[[:space:]]/, "")
      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(normalized)}%"
      users = users.where("replace(last_name || first_name, ' ', '') LIKE ? OR replace(last_name_kana || first_name_kana, ' ', '') LIKE ?", pattern, pattern)
    end
    users = users.where(department_id:) if department_id.present?
    users = users.where(occupation_id:) if occupation_id.present?
    users
  end

  # 受付候補と保存時検証で共通利用する、有効な医師ユーザーの絞り込み。
  # Userが認証アカウントではないため、操作権限はここで扱わない。
  def self.active_physicians
    joins(:occupation).where(mst_users: { active: true }, mst_occupations: { active: true, occupation_code: "physician" }).order(:last_name, :first_name, :id)
  end

  # 受付行の診療科に対して選択可能な医師を返す。
  # 担当診療科が未設定の医師は全診療科で候補に含め、複数診療科の兼務は今回のスコープに含めない。
  def self.active_physicians_for(department)
    active_physicians.where("mst_users.department_id = ? OR mst_users.department_id IS NULL", department.id)
  end

  # 一覧や選択肢で使う姓・名の表示文字列を返す。
  def display_name
    "#{last_name} #{first_name}"
  end

  private

  # Railsのvalidate callbackとして呼ばれ、関連付けた診療科・職種の有効状態を確認する。
  def selected_masters_are_active
    # IDだけが送られた場合も、関連先が存在し利用中であることを確認する。
    errors.add(:department_id, "利用中の診療科を選択してください。") if department_id.present? && !department&.active?
    errors.add(:occupation_id, "利用中の職種を選択してください。") if occupation_id.present? && !occupation&.active?
  end
end
