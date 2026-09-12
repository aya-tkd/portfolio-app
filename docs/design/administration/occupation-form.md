# 職種マスタ：登録・編集

- 親Issue：#15
- 設計Sub-issue：#20（設計 v0.2、承認済み）
- モック：[occupation-form.html](mocks/occupation-form.html)
- 共通UI：[画面・操作の共通設計ルール](../ui-guidelines.md)

## 目的と範囲

職種（医師・看護師など）の基本情報を登録・編集する。将来の権限設計で参照する候補のマスタだが、この画面では認証・認可や職種と権限の対応付けを扱わない。

一覧・検索・削除・利用停止操作、外部連携用コード、カナ名・略名は対象外とする。

## 画面・操作

- URL：`/masters/occupations`
- 新規・編集は親画面から開くモーダルダイアログで行う。
- 職種IDはSQLiteの自動採番で、保存時に決まり編集できない。
- 未保存の変更がある状態で閉じる・Escapeを行うと、破棄確認を表示する。
- 登録成功時はダイアログを閉じ、親画面にID・職種名を含む完了通知を表示する。

| 項目 | 必須 | 仕様 |
|---|---:|---|
| 職種ID | — | 自動採番。表示のみ |
| 職種名 | はい | 100文字以内 |
| 表示順 | はい | 1以上の整数 |
| 利用状態 | はい | 有効 / 無効。初期値は有効 |

フッターの左から登録（DBを変更する色付きボタン）、閉じる（遷移のみのグレーボタン）を置き、閉じるは画面右下端に統一する。

## 処理とHTTP

Vueの`OccupationForm.vue`が画面の入力状態を管理し、`api.js`を通してRails APIを呼ぶ。Railsの`Api::OccupationsController`が`Occupation` Active Recordモデルを使い、`mst_occupations`へ保存する。保存後はJSONを同じ経路でVueへ返す。

| HTTP | 用途 | 成功 | 主な失敗 |
|---|---|---|---|
| GET `/api/occupations/:id` | 編集前の取得 | 200 | 404 |
| POST `/api/occupations` | 新規登録 | 201 | 403, 422 |
| PATCH `/api/occupations/:id` | 更新 | 200 | 403, 404, 422 |

CSRFトークンは保存前に`GET /api/csrf`で取得する。再送による二重登録を避けるため、通信結果が不明な場合は自動再送しない。

## CRUD・関連ファイル

[mst_occupations](../data-model/mst_occupations.md)に対してCreate / Read / Updateを行う。Deleteは行わない。

- `frontend/src/App.vue`：URLに応じて職種マスタを表示する入口
- `frontend/src/features/administration/occupations/components/OccupationWorkspace.vue`：ダイアログ起動と完了通知
- `frontend/src/features/administration/occupations/components/OccupationForm.vue`：入力・未保存確認・保存結果表示
- `frontend/src/features/administration/occupations/api.js`：職種APIのHTTP呼び出し
- `backend/app/controllers/api/occupations_controller.rb`：リクエスト・レスポンス・入力許可項目
- `backend/app/models/occupation.rb`：業務入力制約とテーブル対応

## テスト観点

- 新規登録で自動採番されたIDと保存値が返る。
- 編集で職種名、表示順、利用状態を更新できる。
- 職種名未入力、101文字、表示順0を保存できない。
- 不正なOriginの保存要求を拒否し、未知のIDを404にする。
- ブラウザで新規登録・編集・未保存破棄確認を確認する。
