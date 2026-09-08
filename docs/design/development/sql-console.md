# ローカルDB確認（SQL）

PR #5への追加をユーザーが依頼。対象はローカル開発DBの状態確認。読み取り専用の初期版として実装する。

## 画面と操作

- URL：`/tools/sql`。患者ホストの「DB確認（SQL）を開く」から別タブで開く。
- 左に分類別テーブル一覧、右にSQL入力欄・実行ボタン・ページ送り付き結果表、右下に「閉じる」。閉じるは同じタブで患者画面へ戻る。SQL例・冗長な説明は表示しない。
- 初期SQL：`SELECT * FROM patients ORDER BY id DESC;`。初期表示時には自動実行しない。
- 実行中は入力・実行ボタンを無効化。結果は列名＋行配列で表示し、NULLと空文字を区別する。0件でも列名を表示する。
- 200行ごとの前へ／次へで全結果を閲覧する。総件数は計算せず、次の1行の有無で次へを制御する。SQL変更中はページ送りを無効にし、実行すると1ページ目に戻る。
- 文字列セルは2,000バイトまで（省略表示）、BLOBはサイズを表示。エラー時はSQLを保持し、以前の結果を消す。
- 結果表はスクロール領域上端に不透明なヘッダを固定し、上側から行が透けないよう分離罫線を使う。
- テーブルはマスタ／トランザクション／ログ別に表示し、空分類は「なし」。実際のDBから取得し、分類は `backend/config/table_categories.yml` で指定する。Rails管理テーブルはシステム、対応表にないテーブルは未分類として隠さず表示する。
- テーブル名のダブルクリック（キーボードはEnter/Space）で列名・型・NULL許容・主キーをダイアログに表示する。閉じるは右下、Escapeでも閉じられる。
- 実行は読み取りなのでグレー。DB内容やSQL結果はHTMLとして解釈せず、Vueのテキスト表示を用いる。

## APIと責務

`POST /api/sql-query`へ`{ sql: string, page: integer }`を送る（page省略時1）。通常のCSRFトークンを必要とする。成功200でcolumns/rows/has_next/page/page_size、SQL・ページ不正・実行拒否422でmessageを返す。

元SQLを加工せずページごとに再実行し、前ページ分を読み飛ばす。ORDER BYで一意に並べることを推奨する。閲覧中にDBが変わるとページ間に重複・抜けが起こり得る。深いページは読み飛ばし分の負荷があるため、大量データ用途は対象外。

`GET /api/db-schema` は tables（name/category）、`GET /api/db-schema?table=patients` は table/columns（name/type/nullable/primary_key）を返す。存在しないテーブルは404。development/test限定、読み取り専用接続を使用し、テーブル名はバインドする。任意のPRAGMAや接続先指定は受け付けない。

- `frontend/src/features/development/components/SqlConsole.vue`：入力と結果表示。
- `Api::SqlQueriesController`：development/test限定のHTTP受付。
- `Development::SqlQuery`：サーバー側で固定した現在のSQLite DBへ読み取り専用で接続する。
- `Api::SqlSchemasController` / `Development::SqlSchema`：実DBのテーブルと列のメタデータを取得し、明示した業務分類を付与する。

SELECT/非再帰WITH/集計等に対応。SQLite authorizerでREAD・SELECT・FUNCTIONのみ許可し、拡張/ファイル操作関数は拒否。更新、DDL、ATTACH、PRAGMA、複数SQL文、再帰CTEは対象外。接続先パスはクライアントから受け付けない。SQLは最大10,000文字。リクエストログではSQLをフィルタする。

スキーマ変更・migration追加なし。patients等のReadのみ。既存アプリ同様ローカル・架空データ限定で、公開運用は対象外。ブラウザの15秒タイムアウトはSQLiteクエリの中断を保証しない。大量集計用のツールではない。

## 検証

`backend/test/services/sql_query_test.rb`で結果/NULL/ページ境界/不正ページ/書込禁止/複数文拒否を確認し、`backend/test/controllers/sql_queries_test.rb`でCSRFとJSONを確認。`backend/test/services/sql_schema_test.rb`で分類・列・不正テーブル名を確認。`e2e/sql-console.spec.js`で実行・0件・エラー・HTML文字列・205行のページ送り・ヘッダ固定位置・スキーマ閲覧を確認する。

参照：[SQLite Authorizer](https://www.sqlite.org/c3ref/c_alter_table.html)。
