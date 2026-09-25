# trn_reservation_slot_usages

Issue #64で追加する、予約枠の日時別利用数テーブル。枠全体の定員を診察・設備予約で共有し、保存時に残数を一貫して判定する。

| カラム | 内容 |
| --- | --- |
| reservation_slot_id | `mst_reservation_slots` のFK |
| scheduled_at | 予約開始日時。枠と組み合わせて一意 |
| booked_count | 保存済み予約数。0以上 |
| lock_version | Railsの楽観ロック用カラム |
| created_at / updated_at | Rails管理日時 |

既存予約枠に紐付く予約がある場合、マイグレーション時に予約済み件数を初期化する。取消・変更による利用数の減算は後続Issueで扱う。

予約実績の正本は `trn_appointments`。照会時はreservedを集計し、受付済みも含める。保存時はSQLiteの書込み権を最初のマスタ更新で取得し、同じトランザクションでreserved件数を再集計して利用数を補正する。取消済みは除外する。枠なしの旧予約は自動推定で枠へ対応付けず、容量には加算しない。
