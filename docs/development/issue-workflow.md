# Issue-Centered Development Workflow

## 目的

このプロジェクトでは、親Issueを機能単位の開発管理の正本とします。CodexはLeadとして作業を進め、ユーザーは要求の判断、設計承認、PR受入、mergeを担当します。

GitHubへのIssue、Sub-issue、コメント、PRの書き込みは、ユーザーがその操作を明示的に承認した場合だけに行います。AIはmergeしません。

## 親Issue

親Issueには、目的、要求の要約、受入条件、対象外、関連する業務フロー、判断済み事項、Sub-issue、PRを記録します。Issueは機能単位で作成し、`area:`ラベルで業務領域を分類します。

例：`area: reservation`、`area: reception`、`area: queue`、`area: billing`、`area: administration`、`area: platform`

## Project StatusとIssueの状態

親Issueの進捗はGitHub Projectsの`Status`で管理します。

| Status | Leadの主な作業 | 人間の判断 |
|---|---|---|
| 未着手 | 要求をIssueへ整理する | Issue内容の確認 |
| 設計レビュー | 設計Sub-issue、設計案、ローカルHTMLモックを準備する | 設計Sub-issueをCloseする |
| 実装 | 承認済み設計を基にコード、設計Doc、正式HTMLモックを更新する | 重要変更のみ判断 |
| 自動テスト | テストを実装・実行し、テストSub-issueへ証跡を残す | 原則不要 |
| PR承認待ち | PRを作成し、差分・テスト・Docを整理する | 受入・merge |
| 完了 | 親IssueをCloseし、改善候補を整理する | 必要なら改善Issue作成を承認 |

親IssueはPRがmergeされるまでOpenとします。PR本文に`Closes #<親Issue番号>`を含め、merge時に親IssueをCloseします。

## Sub-issue

### 設計Sub-issue

設計中の議論、レビュー、Human Gateの記録です。次を含めます。

- As-Is / To-Be
- UI変更点とローカルHTMLモック
- 処理スコープ・対象外
- データのCRUD、DB・設定への影響
- 状態遷移
- テスト計画
- PdM、ドメイン、開発者の各観点によるレビュー結果
- 未決事項と判断理由

ユーザーが設計Sub-issueをCloseしたことを、設計承認のシグナルとします。LeadはClose済みであることを確認してから親Issueを`実装`へ進めます。差し戻しの場合は設計Sub-issueをOpenのままにし、設計を更新して再レビューします。

設計レビュー中のHTMLモックは、ローカルの一時ディレクトリで確認します。設計承認後、正式な設計DocとHTMLモックをコードと同じPRへ含め、merge後に`docs/design/`の正本とします。

### テストSub-issue

AIが自動テストの計画、実装、実行結果を残すためのIssueです。

- 要件・設計との整合性確認
- テストケースと実行コマンド
- 実行結果と失敗時の対処
- コード品質・セキュリティ観点の確認

必要な自動テストが成功したとき、LeadはテストSub-issueをCloseできます。失敗が残る場合、親Issueを`PR承認待ち`へ進めません。

### セッションログSub-issue

設計変更、人間からの指摘、重要な判断、PR修正、改善候補を時系列で記録します。会話の逐語録や個人情報、秘密情報は記録しません。

親Issueのmerge後、Leadが完了サマリーと改善候補を記録してCloseします。

## Leadのレビュー・パス

設計ではLeadが次の観点を順に確認し、設計Sub-issueへ結果を残します。

- PdM：利用者価値、受入条件、スコープ、対象外
- ドメイン：患者導線、外来業務フロー、医療上の判断を扱わない境界
- 開発者：実現性、UI、データ、保守性、テスト可能性

テストでは、要件追跡、設計整合性、コード品質・セキュリティ、自動テスト実行の観点を分けて確認します。これらは永続的な別Agentを前提にせず、Leadが役割別のレビュー・パスとして実行します。

## 設計Docとモック

設計承認後、実装と同じPRで次を更新します。

- 画面・操作単位の設計Doc
- テーブル単位の設計Doc
- 画面単位の静的HTMLモック
- 設計索引

UIや処理を変更した場合は、該当する設計Docとモックを同じ作業単位で更新します。テーブルの物理スキーマは実装後はmigrationを正本とし、テーブル設計Docには業務上の意味と設計意図を残します。

## 継続的改善

セッションログに記録した改善候補は、親IssueをCloseした後にレビューします。Skill、テンプレート、テスト観点、Human Gateを変更する場合は、別のプロセス改善Issueを作成し、ユーザー承認後に変更します。
