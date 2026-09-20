# ユーザーマスタ

- 親Issue: #16
- 設計承認: #23 v2

スタッフ基本情報を検索・一覧・登録・編集する。認証アカウントではなく、ログインID・メールアドレス・パスワード・権限は扱わない。

`mst_users` は姓名・カナ姓名・利用状態と、任意の `department_id`／`occupation_id` を持つ。関連先は利用中の診療科・職種だけを選択・保存できる。未所属・未設定はNULLで許容する。

検索はユーザーID完全一致、氏名・カナ氏名部分一致、診療科・職種完全一致をANDで組み合わせる。保存後は同じ条件で再検索し、保存行を再選択する。

経路は `MasterSettingsWorkspace.vue → UserMasterPane.vue → users/api.js → /api/users → Api::UsersController → User → mst_users`。GETは検索、POST/PATCHはCSRFトークン付き保存である。
