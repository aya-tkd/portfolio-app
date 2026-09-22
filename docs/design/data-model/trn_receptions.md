# trn_receptions（受付・診察）

Issue #38 / Design #40。[画面・操作](../outpatient/outpatient-list.md)。1行は1回の受付。患者・日付による一意制約を設けず同日再受診を許す。

| 列 | 意味・制約 |
|---|---|
| id | 自動採番内部ID |
| patient_id / department_id | 必須FK。患者・診療科マスタ |
| reception_number | 必須・一意の表示番号。作成トランザクション内でID由来の文字列へ確定。通常更新不可 |
| business_kind | consultation / equipment。DB CHECK |
| received_at | 必須の受付日時 |
| doctor_user_id | 任意の`mst_users`外部キー。診察受付では対象診療科に一致または診療科未設定の有効な医師ユーザーを設定し、設備受付では空を許容する。削除は制限する |
| doctor_name | 任意の担当医表示名、最大100文字。選択時の氏名スナップショットであり、医師IDの代用にはしない |
| consultation_status | received / called / consulting / consulted。DB CHECK |
| called_at / started_at / finished_at | 初回呼出・診察開始・終了日時 |
| paid_at | 会計完了日時。更新UIは後続Issue |
| lock_version | 必須、初期0。受付と子設備を含めた競合検出 |
| created_at / updated_at | Railsの管理時刻 |

received_at索引、reception_number一意索引、doctor_user_id索引。予約なしでも成立する。診察・予約なし受付では登録時に、対象診療科に一致または診療科未設定の有効な医師ユーザーをDB上で再検証し、氏名をスナップショット保存する。設備実施をhas_manyで所有し、会計待ちは診察と設備から導出する。関連データがある場合の削除は制限する。物理スキーマ正本はmigration/schema。実際の進捗更新はOutpatient::Advanceへ集約。
