# Controllerから診療科属性を受け取り、検証してmst_departmentsテーブルへ保存する。
# 診療科マスタの基本情報だけを所有し、予約枠や診療スケジュールのルールは持たない。
# ブラウザ側の入力検証を信用せず、API経由でも同じ制約を守る最終検証担当。
class Department < ApplicationRecord
  # 業務クラス名と物理テーブルの分類接頭辞を分離し、Railsの慣習的な名前を画面/APIへ漏らさない。
  self.table_name = "mst_departments"

  attr_readonly :id

  validates :name, presence: { message: "入力してください。" }, length: { maximum: 100, message: "100文字以内で入力してください。" }
  validates :kana_name, length: { maximum: 100, message: "100文字以内で入力してください。" }, allow_blank: true
  validates :abbreviation, length: { maximum: 20, message: "20文字以内で入力してください。" }, allow_blank: true
  validates :display_order, numericality: { only_integer: true, greater_than_or_equal_to: 1, message: "1以上の整数を入力してください。" }
  validates :active, inclusion: { in: [true, false], message: "選択肢から選んでください。" }
end
