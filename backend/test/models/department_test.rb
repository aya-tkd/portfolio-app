require "test_helper"

# HTTPを介さず、診療科Modelの検証・自動採番・DB制約を確認する。
class DepartmentTest < ActiveSupport::TestCase
  test "AC-03 persists optional names and database generated id" do
    department = Department.create!(department_attributes)
    assert_predicate department.id, :positive?
    assert_equal "内科", department.reload.name
    assert_equal "ナイカ", department.kana_name
    assert_equal "内", department.abbreviation
  end

  test "AC-04 id is readonly and other attributes can update" do
    department = Department.create!(department_attributes)
    assert_raises(ActiveRecord::ReadonlyAttributeError) { department.id = 98765 }
    department.update!(name: "総合内科", kana_name: nil, abbreviation: nil, display_order: 20, active: false)
    assert_equal ["総合内科", nil, nil, 20, false], department.reload.attributes.values_at("name", "kana_name", "abbreviation", "display_order", "active")
  end

  test "AC-05 validates required length and display order" do
    assert_not Department.new(department_attributes.merge(name: "　 ")).valid?
    assert Department.new(department_attributes.merge(name: "科" * 100, kana_name: "カ" * 100, abbreviation: "略" * 20)).valid?
    assert_not Department.new(department_attributes.merge(name: "科" * 101)).valid?
    assert_not Department.new(department_attributes.merge(kana_name: "カ" * 101)).valid?
    assert_not Department.new(department_attributes.merge(abbreviation: "略" * 21)).valid?
    [nil, 0, -1, 1.5, "abc"].each { |order| assert_not Department.new(department_attributes.merge(display_order: order)).valid?, order.inspect }
  end

  test "AC-05 database check rejects direct invalid display order" do
    assert_raises(ActiveRecord::StatementInvalid) do
      Department.insert_all!([{ **department_attributes, display_order: 0, created_at: Time.current, updated_at: Time.current }])
    end
  end
end
