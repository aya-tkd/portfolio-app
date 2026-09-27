# 職種の基本情報を検証し、mst_occupationsテーブルへ保存するActive Recordモデル。
# 将来の認可で参照候補となるスタッフ属性だが、職種と権限の対応規則は持たない。
class Occupation < ApplicationRecord
  self.table_name = "mst_occupations"

  # 受付での担当医候補を判定する業務コード。認証・認可や資格確認の役割は持たない。
  OCCUPATION_CODES = %w[physician other].freeze

  attr_readonly :id
  validates :name, presence: { message: "入力してください。" }, length: { maximum: 100, message: "100文字以内で入力してください。" }
  validates :display_order, numericality: { only_integer: true, greater_than_or_equal_to: 1, message: "1以上の整数を入力してください。" }
  validates :active, inclusion: { in: [true, false], message: "選択肢から選んでください。" }
  validates :occupation_code, inclusion: { in: OCCUPATION_CODES, message: "選択肢から選んでください。" }

  # 受付で担当医候補に含める職種かを返す。ログイン権限や医師資格の判定ではない。
  def physician?
    occupation_code == "physician"
  end
end
