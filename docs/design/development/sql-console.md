# ローカルDB確認（SQL）

PR #5への追加をユーザーが依頼。対象はローカル開発DBの状態確認。読み取り専用の初期版として実装する。

## 画面と操作

- URL：`/tools/sql`。患者ホストの「DB確認（SQL）を開く」から別タブで開く。
- SQL入力欄、実行ボタン、結果表、SQL例、右下の「閉じる」。閉じるは同じタブで患者画面へ戻る。
- 初期SQL：`SELECT * FROM patients ORDER BY id DESC;`。初期表示時には自動実行しない。
- 実行中は入力・実行ボタンを無効化。結果は列名＋行配列で表示し、NULLと空文字を区別する。0件でも列名を表示する。
- 最大200行、文字列セルは2,000バイトまで、BLOBはサイズを表示。上限超過を明示する。エラー時はSQLを保持し、以前の結果を消す。
- 実行は読み取りなのでグレー。DB内容やSQL結果はHTMLとして解釈せず、Vueのテキスト表示を用いる。

## APIと責務

`POST /api/sql-query`へ`{ sql: string }`を送る。通常のCSRFトークンを必要とする。成功200でcolumns/rows/truncated/limit、SQL不正・実行拒否422でmessageを返す。

- `frontend/src/features/development/components/SqlConsole.vue`：入力と結果表示。
- `Api::SqlQueriesController`：development/test限定のHTTP受付。
- `Development::SqlQuery`：サーバー側で固定した現在のSQLite DBへ読み取り専用で接続する。

SELECT/非再帰WITH/集計等に対応。SQLite authorizerでREAD・SELECT・FUNCTIONのみ許可し、拡張/ファイル操作関数は拒否。更新、DDL、ATTACH、PRAGMA、複数SQL文、再帰CTEは対象外。接続先パスはクライアントから受け付けない。SQLは最大10,000文字。リクエストログではSQLをフィルタする。

スキーマ変更・migration追加なし。patients等のReadのみ。既存アプリ同様ローカル・架空データ限定で、公開運用は対象外。ブラウザの15秒タイムアウトはSQLiteクエリの中断を保証しない。大量集計用のツールではない。

## 検証

`backend/test/services/sql_query_test.rb`で結果/NULL/上限/書込禁止/複数文拒否を確認し、`backend/test/controllers/sql_queries_test.rb`でCSRFとJSONを確認。`e2e/sql-console.spec.js`で画面からの実行・0件・エラー・HTML文字列の表示を確認する。

参照：[SQLite Authorizer](https://www.sqlite.org/c3ref/c_alter_table.html)。
