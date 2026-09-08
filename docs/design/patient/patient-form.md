# 患者登録・編集

- 親Issue：[1](https://github.com/aya-tkd/portfolio-app/issues/1)、設計：[2](https://github.com/aya-tkd/portfolio-app/issues/2)、テスト：[3](https://github.com/aya-tkd/portfolio-app/issues/3)
- 承認版：v0.3＋閉じる配置＋v0.4追補。ユーザーの承認目的Close：2026-09-07T14:05:26Z。
- モック：[patient-form.html](mocks/patient-form.html)
- 共通UI：[ui-guidelines.md](../ui-guidelines.md)

## 目的と範囲

院内スタッフ役が架空患者を登録・編集する共通ダイアログ。ローカルでの学習・テストのみ、ログインなし。患者一覧・検索・削除・外部連携・本番公開は対象外。

## 画面・操作

- 入力順：姓→名→セイ→メイ→生年月日→性別。初期フォーカスは姓。
- 氏名4項目は必須・各100文字以内・空白のみ不可。カナは全角カタカナ・長音・中点・半角/全角空白を許容する。
- 生年月日は任意。入力時はISO日付、実在日、未来日不可。空欄へ戻す更新も可能。
- 性別は未設定・男性・女性・その他。医療的判定には使わない。
- 患者番号は`patient_number`を表示し、この画面では編集不可。内部IDは業務フォームに表示しない。
- フッターは「登録」（青）→「閉じる」（グレー）、閉じるは一番右下。
- 閉じる/Escapeで未保存なら破棄確認。戻るで入力継続、警告付き中止で破棄。背面クリックは閉じない。
- Tabはダイアログ内で循環。閉じた後は呼び出し元へフォーカスを戻す。入力欄のEnterでは送信しない。

## 処理・HTTP・状態

`/patients/new`と`/patients/:id/edit`は同じVueフォームを使う。ホストの内部ID指定は一覧実装までの呼び出し確認用途。画面URLはreplaceStateで変更し、ダイアログ操作の履歴は追加しない。閉じる/保存成功後は`/`へ戻す。再読込・ページ離脱では未保存/送信中ならbeforeunloadを使うが、ブラウザ都合で表示が保証されるものではない。

| HTTP | 処理 | 成功 | 失敗 |
|---|---|---|---|
| GET /api/csrf | CSRFトークン取得 | 200 | 通信エラー |
| GET /api/patients/:id | 内部IDで取得 | 200＋患者JSON | 404 |
| POST /api/patients | 登録 | 201＋患者JSON | 422項目エラー、403 CSRF |
| PATCH /api/patients/:id | 編集 | 200＋患者JSON | 422、403、404 |

Vue → api.js → Railsルート → Controller → Patient → SQLite → JSON → Vueの順。保存中は入力・保存・閉じるを無効化。成功後は患者IDと表示Noを親へ通知して閉じる。入力不正は入力を保持して最初のエラーへフォーカス。読み込み失敗は登録不可、閉じるは可能。通信結果不明は入力を保持し、自動再送せず保存を無効化する（再確認方法の高度化は将来課題）。通信は15秒でタイムアウトするが、DB処理が取り消されたとはみなさない。

## CRUD・責務・設定

[patients](../data-model/patients.md)にCreate/Read/Update。Deleteなし。

- `App.vue`：アプリ全体の入口。
- `features/patients/components/PatientWorkspace.vue`：患者機能の呼び出し、URL、保存結果の通知。
- `PatientForm.vue`：入力・表示状態・破棄確認。
- `features/patients/api.js`：患者固有のAPI呼び出し。
- `shared/api/http.js`：業務に依存しないHTTP通信とエラー分類。
- `Api::PatientsController`：許可パラメータ、Model呼び出し、JSON応答。
- `Patient`：検証、保存、初回番号確定。
- 開発サーバーはループバック限定。ViteはHostを変えずAPIを転送し、RailsのOrigin・CSRF検証を維持。CORSの全許可は設けない。

## テストと制約

AC-01〜04はモデル/API/ブラウザで登録・編集・検証・再取得を確認。AC-05はREADME手順、AC-06は本設計・テーブルDoc・モックと実画面の対応。証跡はテストIssueに残す。

表示No変更や外部連携、同時編集競合の検出、通信結果不明時の照合画面、公開運用は未実装。変更履歴と人間の判断は設計IssueとセッションログIssue #4を参照。
