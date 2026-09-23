# Issue #62 学習記録

関連：[親Issue](https://github.com/aya-tkd/portfolio-app/issues/62)、[設計](https://github.com/aya-tkd/portfolio-app/issues/66)、テストSub-issue #67、セッションログ #68。通常記録。

今回扱った概念は、画面の検索・保存に必要なAPI契約と、予約枠の定義を既存予約から独立させて保護するActive Recordの検証・外部キーである。

| 観点 | 会話に表れた根拠の要約 | 前→後 | 確かさ | 未確認事項 |
|---|---|---|---|---|
| API契約・FE/BEの責務 | 枠マスタでは画面設計DocにURL、HTTP、Input、Output、エラーを置く方針を継続し、予約時刻の入力名とDB分値の内部名を分ける設計を確認した。ユーザーは以前、API契約をFE/BE間の受け渡し条件として捉えている。 | L2維持 | 確認あり | 一つのPOST/PATCHを、実コードのJSON入力からController応答まで自分の言葉で通して説明すること。 |
| Active Recordの永続化 | `mst_reservation_slots`と既存`trn_appointments`のNULL許容FK、予約済み枠の更新制限、楽観ロックを実装した。今回は設計判断・レビュー中心で、Railsの保存呼出しをユーザー自身が説明した新しい根拠はない。 | L1維持 | 接点あり | Controllerの属性許可→Model検証→SQLite更新を実ファイルで追うこと。 |
| Model・Service・DTOの責務 | 枠は予約の実績や容量消費を持たず、定義だけを保存すること、#64が予約取得と容量消費を所有することを業務パターンから判断した。 | L2維持 | 暫定 | #64で日付別の予約実績と枠定義の責務を比較すること。 |

## 実コードを読む順番

1. `frontend/src/features/administration/reservation-slots/components/ReservationSlotMasterPane.vue`：検索条件、一覧、保存後再検索、未保存の左ナビ遷移を扱う。
2. `ReservationSlotForm.vue` と `api.js`：フォーム値をAPI入力へし、CSRF付きPOST/PATCHと項目エラーを扱う。
3. `backend/config/routes.rb` と `backend/app/controllers/api/reservation_slots_controller.rb`：URL・HTTPをControllerと許可項目、曜日/時刻変換へ結び付ける。
4. `backend/app/models/reservation_slot.rb`：業務上の入力制約、初期マスタ、取得済み枠の更新制限を検証する。
5. `backend/db/migrate/20260923000100_create_reservation_slots.rb`：物理テーブルと既存予約へのNULL許容FKを定義する。

次の自然な機会は #64 で、同じ枠ID・日付・開始時刻の定員をどのトランザクションで数え、予約保存の競合をどう扱うかを確認することである。
