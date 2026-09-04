# AI Skill Catalog

このプロジェクトで継続的に使用するCodex Skillの目的と利用条件を定義します。Skill本体はリポジトリ内の[`.agents/skills/`](../../.agents/skills/)を正本としてGit管理します。認証情報や個人用の設定はSkillに含めません。

## portfolio-issue-grooming

会話で受け取った要求を、レビュー可能な親Issueのドラフトへ整理するSkillです。

- 目的・受入条件・対象外・人間判断事項・Sub-issue案を整理する
- ユーザーが明示的に作成を依頼した場合だけ、GitHub Issueと3つのSub-issueを作成する
- 実装、PR作成、Mergeは行わない

## portfolio-issue-delivery

指定された親Issueを、設計・実装・自動テスト・PR準備まで伴走するLead Skillです。

- PdM、ドメイン、開発者、テストの観点でレビューする
- 設計Sub-issueをユーザーがCloseするまで実装しない
- 設計Doc、テーブル設計Doc、HTMLモックをコードと同じPRで更新する
- PR作成はユーザーの明示承認後に行い、承認・Mergeはユーザーが行う

## 共通ルール

- GitHubのIssue・コメント・PRに実在患者情報、認証情報、Token、秘密情報を記載しない
- GitHub ActionsからAIを呼び出さない
- Skillやテンプレートの改善候補はセッションログへ残し、改善Issueとして起票するのはユーザー承認後に限る
- このリポジトリ用Skillを追加・変更する場合は、`.agents/skills/`を更新してGitに含める
