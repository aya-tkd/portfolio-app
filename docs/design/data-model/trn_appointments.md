# trn_appointments（診察・設備予約）

Issue #38 / Design #40。[画面・操作](../outpatient/outpatient-list.md)。予約時点で共通Visit IDを採番しない。

| 列 | 意味・制約 |
|---|---|
| id | 自動採番内部ID |
| patient_id / department_id | 必須FK。設備でも依頼元診療科が必須 |
| reception_id | 任意FK。受付時に採用した予約へ設定 |
| parent_appointment_id | 任意の自己参照FK。設備から診察予約だけを参照 |
| scheduled_at | 必須の予定日時。日付/時刻を一つの値で保持 |
| appointment_kind | consultation / equipment。DB CHECK |
| equipment_name | 設備の場合必須、最大100文字 |
| doctor_name | 任意の予定医表示名、最大100文字 |
| status | reserved / cancelled。DB CHECK。診察状態とは別 |
| created_at / updated_at | Railsの管理時刻 |

scheduled_at索引。受付に紐づく親なし予約は1件までの部分一意索引。同じ受付に別診察を混ぜない。子は親と患者・科・日付・受付が一致することをModelで検証する。受付登録操作の実装時には親子の一括紐付けをトランザクションで実装する（#38では登録APIなし）。

設備予約だけの場合は親なしで表示。受付後は予約を消さず受付側の行へ集約する。関連削除は制限。設備実施は別テーブルに保存し、実施状態を予約のstatusへ混ぜない。
