require "test_helper"

# 実DBの定義を読むこと、未登録分類と不正なテーブル名の扱いを確認する。
class SqlSchemaTest < ActiveSupport::TestCase
  test "lists actual tables with categories and column metadata" do
    schema = Development::SqlSchema.new
    assert_includes schema.call[:tables], { name: "patients", category: "master" }
    columns = schema.call("patients")[:columns]
    assert columns.any? { |column| column[:name] == "id" && column[:primary_key] }
    assert columns.all? { |column| column.key?(:type) && column.key?(:nullable) }
    assert_includes Development::SqlSchema.new(categories: {}).call[:tables], { name: "patients", category: "unclassified" }
    assert_raises(ActiveRecord::RecordNotFound) { schema.call("patients'; DROP TABLE patients;--") }
  end
end
