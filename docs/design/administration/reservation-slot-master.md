# 予約枠マスタ

- 親Issue: [#62](https://github.com/aya-tkd/portfolio-app/issues/62)
- 設計承認: [#66](https://github.com/aya-tkd/portfolio-app/issues/66)（v0.2）
- HTMLモック: [reservation-slot-master.html](mocks/reservation-slot-master.html)

## 目的・利用者

ローカルの架空データで予約を管理するスタッフが、診察・設備の予約枠を検索し、新規登録・編集する。枠は曜日・有効期間・時間帯・間隔・各開始時刻の定員を持つ。診療科・医師は予約入力時の初期値であり、予約可能な対象を固定しない。

患者予約の作成、空き枠の定員消費、日別例外、祝日判定、物理削除、認証認可は対象外で、予約取得は後続のIssue #64が担当する。MRIなどの設備は1設備につき1枠で管理する運用を前提とし、別枠間の設備共有・重複検出は実装しない。

## UI・操作

マスタ設定ワークスペースの「業務マスタ」に予約枠マスタを置く。初期表示と検索は枠名部分一致、枠グループ（診察/設備）、初期診療科、利用状態のAND条件で、表示順・ID順の50件ページングとする。

一覧はID、枠名、グループ、曜日/有効期間、時間/間隔、各枠定員、初期診療科/医師、状態を表示する。選択行がない間は編集できない。保存後は同条件の先頭ページを再取得し、保存行が見えていれば選択、見えなければIDを通知する。

フォームは既存マスタと同じ灰色区切りと固定フッターを使う。「基本情報」に枠名・グループ・表示順・状態、「利用日・時間」に曜日・有効期間・開始/終了・間隔・各枠定員、「予約の初期値」に診療科・医師を配置する。未保存時の閉じる、Escape、左ナビ切替は破棄確認を通す。保存中の再送はしない。

有効な初期診療科を選んだときの医師候補は、所属が同一診療科または未設定で、かつ有効な医師職種のユーザーに限る。診療科の変更で候補外となった医師は解除する。無効化後の既存初期値は「停止中: 名称」として表示を残し、有効枠を保存する際はサーバー側で変更/解除を求める。コンボにはユーザーIDを表示しない。

## ルール・状態

- 曜日は月曜=1から日曜=7の配列で受け、DBではビット集合として保持する。1つ以上を必須とする。
- 有効期間は両端を必須・包含する。開始時刻は00:00〜23:59、終了は00:01〜24:00、日跨ぎは許可しない。
- 時間帯の長さは間隔で割り切れ、定員は1以上整数。容量の単位は「予約枠ID × 対象日 × 分割後開始時刻」で、科・医師の変更によって分割しない。
- 枠が予約から一度でも参照されると、グループ・曜日・期間・時間・間隔・定員を変更できない。名称・表示順・初期値・状態は変更でき、既存予約には波及しない。停止は新規予約対象外にするだけで既存予約を取消さない。
- 既存の文字列設備名・枠なし予約は変更しない。#64で旧未来予約を定員へ扱う前に、明示的な対応付けまたは利用開始日の運用判断を行う。

## API契約

| 操作 | HTTP / URL | Input | Output | 主なエラーと画面の扱い |
|---|---|---|---|---|
| 検索 | GET `/api/reservation_slots` | keyword, slot_group, default_department_id, active, page, per_page（1〜100） | `{items,total,page,per_page}` | 400: 条件エラーを全体表示 |
| 選択肢 | GET `/api/reservation_slots/options` | なし | 有効なdepartments、doctor_users（id/name/department_id） | 取得失敗を全体表示 |
| 詳細 | GET `/api/reservation_slots/:id` | path id | Slot | 404: 全体表示して保存不可 |
| 新規 | POST `/api/reservation_slots` | `reservation_slot`の全入力 | 201 Slot | 403 CSRF、422項目エラー、409競合。入力を保持 |
| 更新 | PATCH `/api/reservation_slots/:id` | 新規項目＋lock_version | 200 Slot | 404、409古い版、422参照済み定義変更。入力を保持 |

Slotは入力項目に加え、`id`、曜日配列、開始/終了時刻、初期値の表示名、`schedule_editable`、`lock_version`を返す。関連表示名・ID・予約数は書込対象にしない。422は`{errors:{field:[message]}}`、409は`{message}`で返す。

## 処理・責務

`MasterSettingsWorkspace.vue`が左ナビを保持し、`ReservationSlotMasterPane.vue`が検索・選択・ページング、`ReservationSlotForm.vue`が入力・未保存保護を担当する。`reservation-slots/api.js`がHTTP契約を実行する。

Railsでは`routes.rb`が`Api::ReservationSlotsController`を選び、Controllerが時刻・曜日を変換して`ReservationSlot`へ渡す。Modelが入力・初期マスタ・参照済み枠の制約を検証し、SQLiteへ保存する。成功応答を受けたPaneは同じ検索条件で再取得する。`Appointment.reservation_slot_id`はNULL許容であり、#62では既存予約を書き換えない。

## CRUD・テスト

| テーブル | C | R | U | D | 用途 |
|---|---:|---:|---:|---:|---|
| mst_reservation_slots | ✓ | ✓ | ✓ | — | 予約枠の定義 |
| trn_appointments | — | 参照 | 任意FK追加のみ | — | 取得済み予約が定義を保護する根拠 |
| mst_departments / mst_users / mst_occupations | — | ✓ | — | — | 初期値候補と医師区分 |

`backend/test/models/reservation_slot_test.rb`は時間・初期値・参照済み変更制限、`backend/test/controllers/reservation_slots_test.rb`はAPI契約・旧予約互換・楽観ロック、`frontend/test/api.test.js`はクライアントのURL/CSRF/JSONを確認する。実画面では長い一覧、1100px/1280px、固定操作、未保存確認を確認する。
