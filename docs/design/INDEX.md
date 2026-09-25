# Design Index

このディレクトリは、承認済みの画面・操作設計、テーブル設計、HTMLモックの索引です。設計Sub-issueは議論と承認の記録、ここに置く文書はmerge後の設計の正本とします。

## 運用

- 共通の文言・ボタン色・配置・ダイアログ挙動は[画面・操作の共通設計ルール](ui-guidelines.md)を参照する。
- 画面・操作ごとに設計Docを作成し、UIがある場合はHTMLモックを対応付ける。
- テーブルごとに設計Docを作成する。
- UI・処理・データを変更するPRでは影響する設計Docを更新し、表示・操作が変わる場合はモックも同じPRで更新する。
- 設計Sub-issueに関連Issue、設計Doc、モックへのリンクを残す。
- 実装後の物理スキーマの正本はmigrationとし、テーブル設計Docは業務上の意味・意図・関連を説明する。

## 画面・操作設計

| 業務領域 | 設計Doc | HTMLモック | 状態 |
|---|---|---|---|
| 外来一覧・進捗更新 | [外来一覧](outpatient/outpatient-list.md) | [HTML](outpatient/mocks/outpatient-list.html) | このブランチに実装あり（Issue #38） |
| マスタ設定（検索・一覧・登録編集導線） | [マスタ設定ワークスペース](administration/master-settings.md) | [HTML](administration/mocks/master-settings.html) | このブランチに実装あり（Issue #48） |
| ユーザーマスタ | [ユーザーマスタ](administration/user-master.md) | [HTML](administration/mocks/user-master.html) | このブランチに実装あり（Issue #16） |
| 患者マスタ（登録・編集） | [患者登録・編集](patient/patient-form.md) | [HTML](patient/mocks/patient-form.html) | 実装・受入済み（Issue #1／PR #5 merge済み） |
| 患者検索・編集起動 | [患者検索](patient/patient-search.md) | [HTML](patient/mocks/patient-search.html) | 実装・受入済み（Issue #33／PR #37） |
| 診療科マスタ（登録・編集） | [診療科登録・編集](administration/department-form.md) | [HTML](administration/mocks/department-form.html) | このブランチに実装あり（Issue #14） |
| 職種マスタ（登録・編集） | [職種登録・編集](administration/occupation-form.md) | [HTML](administration/mocks/occupation-form.html) | Issue #56で受付担当医区分を追加中（基礎実装：Issue #15） |
| 予約枠マスタ（検索・登録・編集） | [予約枠マスタ](administration/reservation-slot-master.md) | [HTML](administration/mocks/reservation-slot-master.html) | Issue #62で実装 |
| 開発支援（DB確認） | [SQL確認画面](development/sql-console.md) | —（追加依頼により実画面で確認） | 実装・受入済み（PR #5 merge済み） |
| 予約 | [患者予約](outpatient/reservation.md) | [HTML](outpatient/mocks/reservation.html) | Issue #64で空き照会・一括登録を実装 |
| 外来受付 | [外来受付](outpatient/reception.md) | [HTML](outpatient/mocks/reception.html) | Issue #56で担当医ユーザー選択を追加中（基礎実装：Issue #43） |
| 診察待ち・呼び出し | 未作成 | 未作成 | 未着手 |
| 会計待ち・会計完了 | 未作成 | 未作成 | 未着手 |

新しい画面・操作の設計Docは、[画面・操作設計テンプレート](templates/screen-operation.md)を複製して作成します。

## テーブル設計

テーブル設計の索引と作成規約は、[Data Model Index](data-model/INDEX.md)を参照してください。

## HTMLモック

設計レビュー中は`tmp/design-mocks/issue-<番号>/`にAs-Is（既存画面がある場合）とTo-Beを置き、設計版・変更点・開き方を設計Sub-issueへ記録します。新規画面はAs-Isなしと明記します。ローカルでのみ閲覧し、外部サービスや実データへ接続しません。

承認後は`docs/design/<業務領域>/mocks/<画面名>.html`へ保存します。画面・操作設計は`docs/design/<業務領域>/<画面・操作名>.md`、テーブル設計は`docs/design/data-model/<テーブル名>.md`とします。例えば患者一覧と患者登録は別文書にし、それぞれに画面・処理・CRUD・クラス責務・設定をまとめます。

修正時は既存の正本を更新し、Issueごとの設計文書を増殖させません。As-Isの履歴はGitと設計Issueに残します。モックは合意用であり、実装済み画面の検証の代わりにはしません。
