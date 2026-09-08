module Development
  # SQLiteの実際のテーブル・列を読み取る。分類だけはリポジトリ内の明示的な定義を使う。
  # テーブル名はバインドし、利用者が任意のPRAGMAや接続先を指定することはできない。
  class SqlSchema
    CATEGORIES = %w[master transaction log system unclassified].freeze

    def initialize(database_path: Rails.root.join(ActiveRecord::Base.connection_db_config.database).to_s,
                   categories: YAML.safe_load_file(Rails.root.join("config/table_categories.yml")))
      @database_path, @categories = database_path, categories
    end

    def call(table = nil)
      payload = nil
      SQLite3::Database.new(@database_path, readonly: true) do |database|
        database.busy_timeout = 2000
        names = database.execute("SELECT name FROM sqlite_schema WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name").flatten
        payload = if table
          raise ActiveRecord::RecordNotFound unless names.include?(table)
          columns = database.execute('SELECT name, type, "notnull", pk FROM pragma_table_xinfo(?)', [table])
          { table: table, columns: columns.map { |name, type, required, pk| { name: name, type: type, nullable: required.zero? && pk.zero?, primary_key: pk.positive? } } }
        else
          { tables: names.map { |name| { name: name, category: CATEGORIES.include?(@categories[name]) ? @categories[name] : "unclassified" } } }
        end
      end
      payload
    end
  end
end
