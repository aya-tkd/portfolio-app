# 診療科登録・編集

- 親Issue：[14](https://github.com/aya-tkd/portfolio-app/issues/14)、設計：[17](https://github.com/aya-tkd/portfolio-app/issues/17)、テスト：[18](https://github.com/aya-tkd/portfolio-app/issues/18)
- 承認版：v0.2〜v0.7。ユーザーの承認目的Close：2026-09-10T12:32:18Z。
- モック：[department-form.html](mocks/department-form.html)
- 共通UI：[ui-guidelines.md](../ui-guidelines.md)

## 目的と範囲

システム管理者が架空の診療科を登録・編集するダイアログ。VueからRails API、SQLite保存、JSON応答、画面の完了通知までの一連を学習・確認する。診療科一覧・検索・削除・外部連携コード・認証認可は対象外。

## 画面・操作

- URLは`/masters/departments`。親画面から「新規」または内部ID指定の「編集」で同じフォームを開く。
- 入力順と初期フォーカスは、診療科名→カナ名→略名→表示順→利用状態。診療科名に初期フォーカスを置く。
- 診療科IDはSQLiteが自動採番し、保存後・編集時に表示する。入力・更新対象にはしない。
- 診療科名は必須・100文字以内。カナ名は任意・100文字以内、略名は任意・20文字以内。初期版ではカナの文字種を限定しない。
- 表示順は必須の1以上の整数。並べ替えUIは一覧機能で扱う。利用状態は有効／無効から必ず選ぶ。
- フッターは「登録」（青、DB保存）→「閉じる」（グレー）。閉じるは最右に置く。
- 閉じる/Escapeで未保存なら破棄確認を出す。Tabはダイアログ内で循環し、閉じた後は呼び出し元へフォーカスを戻す。入力欄のEnterでは送信しない。

## 処理・API連携・状態

| HTTP method / URL | Request（主要項目） | Response（主要データ） | 主なエラーと画面の扱い |
|---|---|---|---|
| GET `/api/departments/:id` | path: 診療科ID | 200: `id`, `name`, `kana_name`, `abbreviation`, `display_order`, `active` | 404: 編集対象なしを表示 |
| POST `/api/departments` | JSON `department`: 必須string `name`、任意string `kana_name`/`abbreviation`、必須integer `display_order`・boolean `active` | 201: 保存した診療科 | 422: 項目エラーを表示、403: CSRFエラーを表示 |
| PATCH `/api/departments/:id` | path: integer診療科ID、body: POSTと同じ項目 | 200: 更新後の診療科 | 422: 項目エラー、403/404: 保存失敗を表示 |

Vueは`api.js`を通じて要求する。書込APIは`GET /api/csrf`で取得したtokenを`X-CSRF-Token`で送る。RailsはRouteからController、Modelへ渡し、成功時は保存値をJSONで返す。422では入力を保持して項目別エラーを表示し、通信結果不明時は自動再送しない。

## CRUD・責務・設定

[mst_departments](../data-model/mst_departments.md)にCreate/Read/Update。Deleteなし。

- `App.vue`：URLで診療科機能を選ぶ入口。
- `DepartmentWorkspace.vue`：フォーム呼び出し、保存結果の通知、内部ID指定の編集確認。
- `DepartmentForm.vue`：入力・ダイアログ・非同期保存・破棄確認。
- `features/administration/departments/api.js`：診療科固有のHTTP契約。
- `shared/api/http.js`：業務に依存しないHTTP・エラー分類。
- `Api::DepartmentsController`：許可パラメータ、Model呼び出し、JSON応答。
- `Department`：業務検証とテーブル対応。IDはreadonly。

Viteはループバックで動作し、`/api`だけをRailsへ中継する。既存のOrigin検証・CSRF検証を維持し、CORS全許可は追加しない。

## テストと制約

AC-01〜05はModel、Rails API、ブラウザで登録・編集・再取得・検証・破棄確認を確認する。AC-06は本設計・テーブル設計・モックと実画面の対応を確認する。証跡はテストIssue #18に残す。

実在情報、外部連携コード、一覧による並び替え、削除、履歴、権限管理は未実装。判断履歴は設計Issue #17とログIssue #19を参照する。
