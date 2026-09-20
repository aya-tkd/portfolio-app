# Issue #16 学習ログ：ユーザーマスタ

- 関連: [親Issue #16](https://github.com/aya-tkd/portfolio-app/issues/16)、[PR #53](https://github.com/aya-tkd/portfolio-app/pull/53)
- 要望は「診療科・職種で絞り込め、検索から編集・DB保存まで完結すること」。認証アカウントとは分離したスタッフ基本情報として実装した。

## 今回のWebの処理経路

`UserMasterPane.vue` が検索条件とフォーム値を保持し、`users/api.js` が GET / POST / PATCH を呼ぶ。`routes.rb` から `Api::UsersController` へ届き、`User` モデルが診療科・職種の存在と利用状態を検証して `mst_users` に保存する。保存後は同じ検索条件で一覧を再取得する。

## 概念の記録

| 概念 | 今回の根拠 | 判定 |
|---|---|---|
| Vueと画面遷移・APIの分離 | 親画面は `@cancelled`、ユーザー画面は `loadUser/searchUsers/saveUser` を責務分離している | L2維持。実装の確認はできたが、ユーザー自身の説明・判断の根拠はまだ不足。 |
| HTTPメソッド | 検索にGET、登録にPOST、更新にPATCHを使い、保存前にCSRFトークンを取得している | L1維持。具体的な使い分けを確認したが、ユーザーからの説明は未確認。 |
| Active Recordと関連検証 | `User` の `belongs_to` とカスタム検証で、存在しない／停止中の関連マスタを422にする | L1維持。モデル経由の保存は実装で確認できたが、概念の説明は未確認。 |

ユーザーの「他のマスタと見せ方は合わせてね」というレビュー判断を、左ナビ、検索カード、一覧選択、フッター操作の共通化に反映した。
