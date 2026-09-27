# ユーザーマスタ

- 親Issue: #16
- 設計承認: #23 v2

スタッフ基本情報を検索・一覧・登録・編集する。認証アカウントではなく、ログインID・メールアドレス・パスワード・権限は扱わない。

`mst_users` は姓名・カナ姓名・利用状態と、任意の `department_id`／`occupation_id` を持つ。関連先は利用中の診療科・職種だけを選択・保存できる。未所属・未設定はNULLで許容する。

検索はユーザーID完全一致、氏名・カナ氏名部分一致、診療科・職種完全一致をANDで組み合わせる。保存後は同じ条件で再検索し、保存行を再選択する。

経路は `MasterSettingsWorkspace.vue → UserMasterPane.vue → users/api.js → /api/users → Api::UsersController → User → mst_users`。GETは検索、POST/PATCHはCSRFトークン付き保存である。

## 診療科・職種マスタと共通のフォーム

PR #53の表示差異への指摘を受け、登録・編集は `UserForm.vue` に分離した。`UserMasterPane.vue` は検索条件・選択行と一覧復帰を、`UserForm.vue` は入力・項目別エラー・未保存確認と保存API呼び出しを担当する。

- `DepartmentForm.vue` / `OccupationForm.vue` と同じ `master-form`、`dialog-head/body/foot`、`fields/field`、`form-control/form-select` を使う。寸法・色・余白は共通の `shared/styles/style.css` を参照する。
- 上からタイトル＋新規／編集バッジ、ユーザーID（新規時は自動採番）、基本情報、ユーザー情報見出し、入力欄、固定フッターを配置する。
- 姓／名、セイ／メイ、診療科／職種を左右ペアで配置する。利用状態は次の行。姓名・カナ姓名・利用状態に必須印を表示する。
- 各ラベルを入力左側に揃え、エラーは当該入力の直下。422時は入力を保持して先頭のエラーへフォーカスする。
- フッターは「＊ 必須項目」と右寄せの「登録 → 閉じる」。本文だけスクロールする。
- 変更後の閉じるは「戻る／中止」の破棄確認を表示する。保存結果不明時は再送を止め、一覧確認を案内する。

今回の修正は既存マスタに見せ方を合わせる依頼に基づく。API・DB契約は変更しない。

## API連携

ユーザー画面で利用するAPIの概要。診療科・職種の選択肢は既存の各マスタAPIを利用し、ここではユーザー操作に必要な項目に絞る。

| HTTP method / URL | Request（query / bodyの主要項目） | Response（主要データ） | 主なエラーと画面の扱い |
|---|---|---|---|
| GET `/api/users` | 任意string `user_id`/`name`、integer `department_id`/`occupation_id` query（複数指定はAND） | 200: ユーザー基本情報、診療科名・職種名の配列 | 通信エラー: 一覧領域に失敗を表示 |
| GET `/api/users/:id` | path: integer内部ユーザーID | 200: ユーザー基本情報と関連名 | 404: 編集対象なしを表示 |
| POST `/api/users` | JSON `user`: 必須string姓名・カナ、任意integer `department_id`/`occupation_id`、必須boolean `active` | 201: 保存したユーザー | 422: 項目エラー、403: CSRFエラーを表示 |
| PATCH `/api/users/:id` | path: integer内部ID、body: POSTと同じ項目 | 200: 更新後のユーザー | 422: 項目エラー、403/404: 保存失敗を表示 |

検索条件用の選択肢は`GET /api/departments?active=true`と`GET /api/occupations?active=true`を使用する。書込APIでは`GET /api/csrf`でtokenを取得して送信する。
