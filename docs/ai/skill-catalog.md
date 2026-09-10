# AI Skill Catalog

このプロジェクトで継続的に使用するCodex Skillの目的と利用条件を定義します。Skill本体はリポジトリ内の[`.agents/skills/`](../../.agents/skills/)を正本としてGit管理します。認証情報や個人用の設定はSkillに含めません。

## portfolio-issue-grooming

会話で受け取った要求を、レビュー可能な親Issueのドラフトへ整理する**Issue管理専用**Skillです。

- 目的・受入条件・対象外・人間判断事項・Sub-issue案を整理する
- ユーザーが明示的に作成を依頼した場合だけ、GitHub Issueと3つのSub-issueを作成する
- 作成後は親Issueを`未着手`に保ち、ブランチ作成・設計モック・設計着手・実装・PR作成・Mergeは行わない
- 開発を始めるには、別途「Issue #Nを進めて」など、対象Issueを指定した依頼が必要

## portfolio-issue-delivery

明示的に開始を依頼された親Issueを、設計・実装・自動テスト・PR準備まで伴走するLead Skillです。Issueが存在するだけでは開始しません。

- PdM、ドメイン、開発者、テストの観点でレビューする
- 設計Sub-issueをユーザーがCloseするまで実装しない
- 設計Doc、テーブル設計Doc、HTMLモックをコードと同じPRで更新する
- PR作成は依頼・既存の承認範囲で行い、Approve・Mergeはユーザーが行う
- 専用ブランチ、承認対象版、テスト証跡、再開情報を管理する
- 実装に沿ったWeb概念の説明と、ポートフォリオとしての成果・判断根拠を残す
- AIがローカル受入環境・URL・UAT手順を準備し、各工程完了前の小改善を同じPRへ含める。PR作成成功時にログをCloseし、merge後は対象ブランチ削除とmain復帰を行う

## 共通ルール

- GitHubのIssue・コメント・PRに実在患者情報、認証情報、Token、秘密情報を記載しない
- GitHub ActionsからAIを呼び出さない
- 各工程完了前の小改善は[継続的改善](../development/issue-workflow.md#継続的改善)の範囲で毎回の再依頼なしに反映する。権限・Human Gateの変更、大きな改善、改善Issueの起票は別途承認する
- このリポジトリ用Skillを追加・変更する場合は、`.agents/skills/`を更新してGitに含める

実行権限・承認・Statusの正本は[Issue中心の開発フロー](../development/issue-workflow.md)、学習支援の正本は[協働方針](working-agreement.md)とする。Skillはこれらを実行する入口であり、異なる承認ルールを重複定義しない。
