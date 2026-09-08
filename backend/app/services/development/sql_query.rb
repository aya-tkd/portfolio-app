module Development
  # DB確認画面からのSQLを、アプリとは別の読み取り専用接続で実行する。
  # 接続先はサーバーが決める。SQLiteの操作許可で書込・ATTACH・PRAGMA等を拒否する。
  class SqlQuery
    class InvalidQuery < StandardError; end
    MAX_ROWS = 200
    MAX_CELL_BYTES = 2000

    def initialize(database_path: Rails.root.join(ActiveRecord::Base.connection_db_config.database).to_s)
      @database_path = database_path
    end

    def call(sql)
      raise InvalidQuery, "SQLを入力してください（最大10,000文字）。" unless sql.is_a?(String) && sql.strip.present? && sql.length <= 10_000

      database = SQLite3::Database.new(@database_path, readonly: true)
      database.busy_timeout = 2000
      # SQLite公式の操作コード：READ=20、SELECT=21、FUNCTION=31。
      # 字句だけの判定ではWITHやコメントを見落とすため、SQLiteの解析結果で制限する。
      database.authorizer do |action, _first, function, *_rest|
        allowed = [20, 21, 31].include?(action)
        allowed &&= !%w[load_extension readfile writefile].include?(function.to_s.downcase) if action == 31
        allowed ? 0 : 1
      end
      database.prepare(sql) do |statement|
        raise InvalidQuery, "実行できるSQLは1文ずつです。" unless statement.remainder.to_s.strip.empty?
        rows = []
        result = statement.execute
        columns = result.columns
        raise InvalidQuery, "SELECTなどの読み取りSQLを入力してください。" if columns.empty?
        result.each do |row|
          rows << row.map { |value| display_value(value) }
          break if rows.length > MAX_ROWS
        end
        { columns: columns, rows: rows.first(MAX_ROWS), truncated: rows.length > MAX_ROWS, limit: MAX_ROWS }
      end
    rescue SQLite3::Exception => error
      raise InvalidQuery, "SQLを実行できません（読み取り専用）：#{error.message}"
    ensure
      database&.close
    end

    private

    def display_value(value)
      return value unless value.is_a?(String)
      return "[BLOB: #{value.bytesize} bytes]" if value.encoding == Encoding::BINARY
      return value if value.bytesize <= MAX_CELL_BYTES
      value.byteslice(0, MAX_CELL_BYTES).force_encoding(Encoding::UTF_8).scrub + "…（省略）"
    end
  end
end
