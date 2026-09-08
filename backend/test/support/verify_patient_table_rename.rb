# 実DBを触らず、メモリDBで新規構築・改名・逆移行・再適用を検証する。
# backendから bundle exec ruby bin/rails runner test/support/verify_patient_table_rename.rb で実行。
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
context = ActiveRecord::Base.connection_pool.migration_context
context.migrate(20260907000100)
connection = ActiveRecord::Base.connection
connection.execute("INSERT INTO patients (id, patient_number, last_name, first_name, last_name_kana, first_name_kana, sex, created_at, updated_at) VALUES (7, '0007', '架空', 'テスト', 'カクウ', 'テスト', '', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)")
expected = connection.select_all("SELECT * FROM patients").to_a
context.migrate
raise "Forward data mismatch" unless connection.select_all("SELECT * FROM mst_patients").to_a == expected
raise "Unique index missing" unless connection.indexes(:mst_patients).any? { |index| index.unique && index.columns == ["patient_number"] }
raise "Check constraint missing" if connection.check_constraints(:mst_patients).empty?
context.migrate(20260907000100)
raise "Rollback data mismatch" unless connection.select_all("SELECT * FROM patients").to_a == expected
context.migrate
Patient.reset_column_information
raise "Model mapping failed" unless Patient.find(7).patient_number == "0007"
puts "PASS: fresh migrations, rename, rollback, reapply, rows, unique index, CHECK and model mapping"
