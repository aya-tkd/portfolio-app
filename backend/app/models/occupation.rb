# 職種の基本情報を検証し、mst_occupationsテーブルへ保存するActive Recordモデル。
# 将来の認可で参照候補となるスタッフ属性だが、職種と権限の対応規則は持たない。
class Occupation < ApplicationRecord
  self.table_name = "mst_occupations"

  attr_readonly :id
  validates :name, presence: { message: "入力してください。" }, length: { maximum: 100, message: "100文字以内で入力してください。" }
  validates :display_order, numericality: { only_integer: true, greater_than_or_equal_to: 1, message: "1以上の整数を入力してください。" }
  validates :active, inclusion: { in: [true, false], message: "選択肢から選んでください。" }
end
