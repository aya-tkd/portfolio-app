# Security Development Guidelines

このリポジトリは公開されるため、Fork、外部Issue、外部Pull Requestを信頼しません。目標は外部からの閲覧やForkを止めることではなく、未承認変更・CI悪用・秘密情報漏えいを防ぐことです。

## GitHub設定（人間が確認して設定）

### 現在の基本設定

- `main`への直接pushを禁止するRuleset
- Pull Requestを必須にする
- force pushとブランチ削除を禁止する
- 2FAまたはPasskeyを有効にする
- Dependabot alerts / security updatesを有効にする
- Secret scanning / Push protectionを有効にする
- Private vulnerability reportingを有効にする
- GitHub Actionsの既定権限を読み取り専用にする

### CI導入後に追加する設定

- CIのStatus checksを`main`へのmerge条件にする
- コラボレーターによるレビューが可能になった時点で、Pull Requestの承認レビューを必須にする
- CodeQLなどのCode scanningを、実装する言語とCI構成に合わせて有効にする

AgentはこれらのGitHub Settingsを独断で変更しません。

## GitHub Actions

- Workflowごとに最小限の`permissions`を明示する
- ForkからのPull RequestでSecretsを使用しない
- `pull_request_target`で外部コードをcheckoutして実行しない
- Issue本文、PR本文、コメントをShellコマンドとして実行しない
- 外部入力をコマンド引数やファイルパスへ渡す場合は検証する
- Actionのバージョンを確認し、可能ならコミットSHAで固定する
- 書き込み権限が必要なWorkflowは用途を限定し、レビュー対象にする

## 秘密情報

`.env`、鍵、Token、パスワード、Rails credentials、個人情報をcommitしません。漏えいが疑われる場合は値を表示せず、直ちに失効・ローテーションを検討します。詳細は[SECURITY.md](../../SECURITY.md)と[AGENTS.md](../../AGENTS.md)を参照します。

## IssueとPR

### 依存関係の脆弱性対応

- 着手前に対象パッケージ・advisoryに対応する既存IssueとPRを確認する。DependabotなどBot作成のPRも含め、再利用できる更新を重複作成しない。
- 既存PRを使う場合も、親Issue・設計承認・テスト証跡との関連を明示する。別PRが必要なら理由と置換関係を記録する。
- 置換したPRは両方をmergeせず、対応PRのmergeを確認してから承認範囲内で理由を残してCloseする。通知のdismissで修正済みと扱わない。
- mainへのmerge後に対象通知のfixed状態を確認する。再評価待ちは未確認として記録する。

根拠：Issue #8／PR #12の対応時にDependabot PR #6が重複していた。今後は更新作業前の確認対象に含める。

Issue Formやテンプレートを導入する際は、秘密情報・個人情報を投稿しないよう案内します。不審な投稿は実行せず、削除・ロック・報告などGitHubの機能で対応します。
