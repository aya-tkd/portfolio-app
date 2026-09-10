# mst_departments

- 親Issue #14／設計Issue #17。
- [migration](../../../backend/db/migrate/20260910000100_create_departments.rb)
- Rubyモデルは`Department`、APIは`/api/departments`。`self.table_name`で物理テーブル名を対応付ける。
- 利用画面：[診療科登録・編集](../administration/department-form.md)（Create/Read/Update、Deleteなし）

## 目的・カラム

管理者が維持する診療科の基本情報。予約枠、診療スケジュール、診療行為、外部連携コードは持たない。

| カラム | 型 | NULL | 制約・意味 |
|---|---|---|---|
| id | integer | 不可 | SQLite自動採番PK。内部参照・APIの対象特定。変更不可 |
| name | string | 不可 | 正式名称。必須、100文字以内。DB CHECKも適用 |
| kana_name | string | 可 | 読み補助。100文字以内。初期版では文字種を限定しない |
| abbreviation | string | 可 | 短縮表示。20文字以内。外部連携コードではない |
| display_order | integer | 不可 | 1以上。将来の一覧における基本表示順 |
| active | boolean | 不可 | 初期値true。有効／無効の利用状態 |
| created_at / updated_at | datetime | 不可 | Rails管理の作成・更新時刻。完全な変更監査ログではない |

## キー・整合性

主キーは`id`のみ。初期版に外部キー・一意な外部連携コードはない。`id`はControllerの許可項目から除外し、Modelのreadonlyで通常更新も拒否する。

名称・カナ名・略名の文字数、表示順1以上、利用状態booleanをSQLite CHECK制約にも置く。Modelの検証は画面へ項目別メッセージを返すための利用者向け境界を担う。SQLiteの文字列limitだけには依存しない。

Model/API/ブラウザテストで、自動採番、ID更新拒否、任意項目のNULL更新、表示順の不正値、CSRF拒否、保存後の再取得を確認する。詳細な経緯は設計Issue #17・ログIssue #19を参照する。
