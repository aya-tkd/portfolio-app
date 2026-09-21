# Issue #56 学習記録

関連：[親Issue](https://github.com/aya-tkd/portfolio-app/issues/56)、[設計](https://github.com/aya-tkd/portfolio-app/issues/57)、テストSub-issue #58、セッションログ #59。通常記録。

今回扱った概念は、画面がAPIで利用できるデータを判断するための「API契約」と、選択したユーザーIDを保存時にサーバー側でも再検証する境界である。

| 観点 | 会話に表れた根拠の要約 | 前→後 | 確かさ | 未確認事項 |
|---|---|---|---|---|
| API契約・FE/BEの責務 | チャットで、API契約を「FEからBEへ受け渡しするパラメータ条件の変更」と捉え、画面設計DocにURL・HTTPメソッド・Input・Output・主なエラーを置く運用を選択した。 | 新規 → L2 | 確認あり | 実コードの一APIについて、入力→Controller→応答を自分の言葉で一続きに説明すること。 |
| HTTPメソッド | 今回はGET候補取得とPOST受付登録を実装したが、メソッドごとの意図をユーザー自身が説明した追加の根拠はない。 | L1維持 | 確認あり | 次の画面変更で、読取・作成・更新の選択を実コードと対応付ける。 |
| Model・Service・DTOの責務 | サーバーで候補を再検証する実装を扱ったが、責務分担をユーザー自身が説明した追加の根拠はない。 | L2維持 | 暫定 | `doctor_user_id`がVueからServiceまで渡る経路を実ファイルで追う。 |

## 実コードを読む順番

1. `frontend/src/features/receptions/components/ReceptionWorkspace.vue`：候補の`doctor_users`を選択肢にし、診察・予約なし受付で`doctor_user_id`を送る。
2. `frontend/src/features/receptions/api.js`：候補取得のGETと、受付登録のPOSTをHTTPへ変換する。
3. `backend/app/controllers/api/receptions_controller.rb`：APIの許可入力を`doctor_user_id`に限定する。
4. `backend/app/models/user.rb`：有効な医師ユーザーの選択条件を共通化する。
5. `backend/app/services/reception/register.rb`：送られたIDを再検証し、受付・予約へIDと氏名スナップショットをトランザクションで保存する。

次の自然な機会は、Issue #60で画面設計DocのAPI契約表を標準化する際に、既存のAPI一件をInput・Output・エラーまで読み解くことである。
