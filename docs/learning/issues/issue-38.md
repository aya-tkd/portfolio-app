# Issue #38 学習記録

関連：[親Issue](https://github.com/aya-tkd/portfolio-app/issues/38)、[設計](https://github.com/aya-tkd/portfolio-app/issues/40)、[セッションログ](https://github.com/aya-tkd/portfolio-app/issues/41)。通常の開発会話に基づく記録。

今回の概念は「複数テーブルを一覧DTOへ組み立てる責務」と「画面の操作から状態を保存する経路」。ユーザーは予約と受付の発生時点の違い、同日再受診の識別、設備の独立した進捗と会計条件を具体化した。既存の業務・RDB設計経験の証拠であり、Rails実装の習得と混同しない。

| 観点 | 観測と評価 |
|---|---|
| Model・Service・DTO | 既存L2（暫定）を維持。表示行と業務レコードの粒度を検討したが、今回の実コードをユーザー自身が説明した証拠はまだない |
| VueとAPIの分離 | L2を維持。動的ボタンと階層表示の要求は明確。非同期保存・再描画の具体的な理解は今後の自然な会話で確認 |
| HTTP・Active Record | 各L1を維持。今回の設計承認だけで習得とは判定しない |

## 実コードを読む順番

1. `frontend/src/features/outpatients/components/OutpatientListWorkspace.vue`：検索条件・親子行を表示。advanceから次の操作を送る。
2. 同機能の `api.js`：GETは検索、PATCHは操作名と取得時のversionを送る。共通http.jsがHTTP失敗を例外として返す。
3. `backend/config/routes.rb` → `app/controllers/api/outpatients_controller.rb`：URLとメソッドに対応する窓口。
4. `app/queries/outpatient/list_query.rb`：予約・受付を選択。`app/presenters/outpatient/row_presenter.rb`が画面用DTOへ変換。
5. `app/services/outpatient/advance.rb`：現在の状態とversionを照合し、Active Record経由でDBを更新。診察・設備の更新は同じ受付のversionで競合を検出する。
6. 保存済みDTOがVueへ戻る。成功時だけ行を置換し、失敗時は再検索まで操作を止める。

C#でいう画面向けDTOに相当するのがPresenterの戻り値。Queryはその材料を取り出し、Serviceは操作を確定する。Modelには関連と検証、受付の会計待ち判定を置く。クラス数やテーブル数だけでModel/Serviceの境界を決めない。

次の学習機会：PRのコードを見ながら会計待ち判定や別タブ競合時の応答を必要に応じて説明する。理解度測定の出題はしない。
