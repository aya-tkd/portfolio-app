require "test_helper"

class OccupationTest < ActiveSupport::TestCase
  test "AC-03 persists automatic id and optional active state" do
    occupation = Occupation.create!(occupation_attributes)
    assert_predicate occupation.id, :positive?
    occupation.update!(active: false, display_order: 20)
    assert_equal [false, 20], occupation.reload.attributes.values_at("active", "display_order")
  end

  test "AC-04 and AC-05 protect id and validate values" do
    occupation = Occupation.create!(occupation_attributes)
    assert_raises(ActiveRecord::ReadonlyAttributeError) { occupation.id = 99 }
    assert_not Occupation.new(occupation_attributes.merge(name: "", display_order: 0)).valid?
    assert Occupation.new(occupation_attributes.merge(name: "職" * 100)).valid?
    assert_not Occupation.new(occupation_attributes.merge(name: "職" * 101)).valid?
  end
end
