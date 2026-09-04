# Development Process

開発はIssueを単位に進めます。作業の規模に応じて、要件、設計、実装、テスト、レビューの段階を明示します。具体的な状態遷移、Sub-issue、Human Gateは[Issue中心の開発フロー](issue-workflow.md)を正本とします。

## 基本フロー

1. 要件を親Issueに整理する
2. 設計・テスト・セッションログのSub-issueを作成する
3. 設計Sub-issueでHuman Gateを通過する
4. 実装、テスト、設計Docの更新を行う
5. PRでコード・設計Doc・モック・テスト結果を確認する
6. 人間が受入・mergeし、親IssueをCloseする

Codexは、依頼された範囲を超えて大規模な設計変更やmergeを独断で行いません。

## Human Gateの例

- 要件の確定
- 技術スタックや公開範囲の決定
- 認証・認可、個人情報、秘密情報に関わる変更
- 大きなアーキテクチャ変更
- GitHub Settings、Ruleset、Secrets、権限の変更
- リリースや本番公開

## AI Activity

AIが作成・変更した内容、判断理由、テスト結果、人間が確認・判断した事項をIssueまたはPRから追跡できるようにします。秘密情報や個人情報は記録しません。

GitHub ActionsからAIを呼び出す運用は採用しません。AI作業はCodexとの対話およびローカル実行で行い、GitHub Actionsは将来必要になった場合も通常のCI用途に限定します。
