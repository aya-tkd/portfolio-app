ENV["RAILS_ENV"] = "test"
require_relative "../config/environment"
require "rails/test_help"

# テスト専用DBと架空データの共通準備。実在患者の情報は使用しない。
class ActiveSupport::TestCase
  def patient_attributes
    { last_name: "デモ患者", first_name: "一郎", last_name_kana: "デモカンジャ", first_name_kana: "イチロウ", birth_date: nil, sex: "" }
  end

  def department_attributes
    { name: "内科", kana_name: "ナイカ", abbreviation: "内", display_order: 10, active: true }
  end
end
