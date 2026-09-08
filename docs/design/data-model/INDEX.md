# Data Model Index

テーブル設計はテーブル単位で管理します。テーブルを追加・変更する場合は、対応するテーブル設計Docと、影響する画面・操作設計Docを同じPRで更新します。

## テーブル一覧

| テーブル | 設計Doc | 目的 | 状態 |
|---|---|---|---|
| mst_patients | [mst_patients.md](mst_patients.md) | 架空患者の基本情報・内部IDと表示No | Issue #1実装 |

## テーブル命名ルール

- 業務テーブルは分類接頭辞＋複数形snake_caseとする。
- マスタ：`mst_`（例：`mst_patients`）。継続して参照・更新する基本情報。
- トランザクション：`trn_`（例：`trn_reservations`）。予約・受付など業務の発生・進行を表す情報。
- ログ：`log_`（例：`log_operation_events`）。操作履歴など時系列の記録。
- 分類は更新頻度でなく業務上の役割で判断する。曖昧な場合は設計時に合意する。
- Rails管理用の`schema_migrations`・`ar_internal_metadata`は変更しない。
- モデル名・API・画面URLには接頭辞を波及させず、Railsモデルの`self.table_name`で対応付ける。
- SQLツールの分類対応表`backend/config/table_categories.yml`も同時に更新する。
- 適用済みmigrationは変更せず、改名にはデータを保持する新しいmigrationを追加する。

## 作成規約

- ファイル名は実装上のテーブル名と一致させる。
- テーブル設計Docは、[テーブル設計テンプレート](templates/table.md)を複製して作成する。
- migrationが実装後の物理スキーマの正本である。
- テーブル設計Docには、業務上の意味、関連する画面・操作、制約の意図を記録する。
