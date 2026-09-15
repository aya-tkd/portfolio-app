# trn_equipment_executions（設備実施）

Issue #38 / Design #40。[画面・操作](../outpatient/outpatient-list.md)。1行は受付に属する1設備の実施。

| 列 | 意味・制約 |
|---|---|
| id | 自動採番内部ID |
| reception_id | 必須FK。診察に付随する設備と検査のみの両方で受付に所属 |
| appointment_id | 任意FK・一意。元の設備予約。予約なし設備も表現可能 |
| department_id | 必須FK。依頼元診療科。受付の科と一致 |
| equipment_name | 必須、最大100文字。設備マスタ整備前の名称 |
| scheduled_at | 任意の予定日時 |
| completed_at | NULLなら未実施。実施操作で現在時刻を一度だけ保存 |
| cancelled_at | 対象設備を会計判定から除外する日時。取消UIは対象外 |
| created_at / updated_at | Railsの管理時刻 |

元予約がある場合は設備種別・受付・科一致を検証。患者は受付から取得し重複保存しない。Outpatient::Advanceが所属受付のversionを更新してから実施を保存する。同一受付の診察操作とも競合を検出する。将来の設備別実施一覧もこのモデルを利用する。設備が先に完了しても、診察が未終了なら会計待ちにはならない。

初版の検査のみ受付は設備1件で1行。複数設備を先頭1件だけ表示して隠さないようModelで追加を拒否する。複数の独立設備を1受付へまとめる操作は後続Issueで画面と併せて設計する。
