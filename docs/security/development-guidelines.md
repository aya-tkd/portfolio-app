# Security Development Guidelines

このリポジトリは公開されるため、Fork、外部Issue、外部Pull Requestを信頼しません。目標は外部からの閲覧やForkを止めることではなく、未承認変更・CI悪用・秘密情報漏えいを防ぐことです。

## GitHub設定（人間が確認して設定）

- `main`への直接pushを禁止するRuleset
- Pull Request、レビュー、CI成功を必須にする
- force pushとブランチ削除を禁止する
- 2FAまたはPasskeyを有効にする
- Dependabot alerts / security updatesを有効にする
- Secret scanning / Push protectionを有効にする
- Code scanning / CodeQLを有効にする

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

Issue Formやテンプレートで秘密情報・個人情報を投稿しないよう案内します。不審な投稿は実行せず、削除・ロック・報告などGitHubの機能で対応します。
