require "test_helper"
require "tmpdir"

# 一時DBで実行制限を検証する。患者の開発DBには変更を加えない。
class SqlQueryTest < ActiveSupport::TestCase
  setup do
    @directory = Dir.mktmpdir("sql-console")
    @path = File.join(@directory, "sample.sqlite3")
    SQLite3::Database.new(@path) do |db|
      db.execute("CREATE TABLE sample (id INTEGER, name TEXT)")
      201.times { |i| db.execute("INSERT INTO sample VALUES (?, ?)", [i, i.zero? ? nil : "架空"] ) }
    end
    @query = Development::SqlQuery.new(database_path: @path)
  end
  teardown { FileUtils.remove_entry(@directory) }

  test "columns null empty results aggregates and row limit" do
    result = @query.call("SELECT id, name FROM sample ORDER BY id;")
    assert_equal %w[id name], result[:columns]
    assert_equal [0, nil], result[:rows].first
    assert_equal 200, result[:rows].size
    assert result[:has_next]
    last = @query.call("SELECT id, name FROM sample ORDER BY id;", page: 2)
    assert_equal [[200, "架空"]], last[:rows]
    assert_not last[:has_next]
    assert_equal 2, last[:page]
    assert_equal 200, last[:page_size]
    assert_equal [], @query.call("SELECT * FROM sample LIMIT 200", page: 2)[:rows]
    [0, -1, "invalid", 1.5, nil].each do |page|
      assert_raises(Development::SqlQuery::InvalidQuery) { @query.call("SELECT 1", page: page) }
    end
    assert_equal [[201]], @query.call("SELECT COUNT(*) FROM sample")[:rows]
    assert_equal [], @query.call("SELECT * FROM sample WHERE 0")[:rows]
    assert_equal [[1]], @query.call("WITH x AS (SELECT 1 AS n) SELECT n FROM x")[:rows]
  end

  test "rejects mutations attachments pragmas multiple statements and invalid SQL" do
    ["DELETE FROM sample", "UPDATE sample SET name='x'", "DROP TABLE sample", "CREATE TABLE other (id)",
     "ATTACH DATABASE ':memory:' AS other", "PRAGMA writable_schema=ON", "SELECT load_extension('x')",
     "SELECT 1; DELETE FROM sample", "SELECT FROM", "", nil].each do |sql|
      assert_raises(Development::SqlQuery::InvalidQuery, sql.inspect) { @query.call(sql) }
    end
    assert_equal [[201]], @query.call("SELECT COUNT(*) FROM sample")[:rows]
  end
end
