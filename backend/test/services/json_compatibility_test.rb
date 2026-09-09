require "test_helper"
require "stringio"

# Issue #8: RailsのJSON解析と通常のIO出力が修正版でも動くことを確認する。
# 攻撃用入力ではなく架空の日本語データを往復させ、既存APIの互換性を守る。
class JsonCompatibilityTest < ActiveSupport::TestCase
  test "approved JSON major and minimum patched version are loaded" do
    assert Gem::Requirement.new(">= 2.19.9", "< 3.0").satisfied_by?(Gem::Version.new(JSON::VERSION))
  end

  test "Rails JSON round trip retains Japanese text null and numbers" do
    value = { "name" => "架空患者", "number" => 7, "birthday" => nil }
    assert_equal value, ActiveSupport::JSON.decode(ActiveSupport::JSON.encode(value))
  end

  test "ordinary IO JSON generation remains compatible" do
    value = { "name" => "架空患者", "enabled" => true }
    io = StringIO.new
    JSON.dump(value, io)
    assert_equal value, JSON.parse(io.string)
  end
end
