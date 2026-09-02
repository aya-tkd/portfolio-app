# Documentation Index

このディレクトリは、プロジェクトの背景・設計・開発プロセス・AI活用方針の正本を管理します。
同じ情報を複数の文書へコピーせず、概要が必要な場合は正本へのリンクを使用します。

## 文書の配置

| 分野 | 文書 | 役割 |
|---|---|---|
| Project | [purpose.md](project/purpose.md) | ポートフォリオの目的と評価対象 |
| Architecture | [overview.md](architecture/overview.md) | システム全体の構成と責務 |
| Development | [process.md](development/process.md) | Issue、Human Gate、実装、テスト、レビューの流れ |
| Development | [definition-of-done.md](development/definition-of-done.md) | 作業完了条件 |
| Learning | [user-technical-profile.md](learning/user-technical-profile.md) | 技術理解度と説明方針 |
| AI | [working-agreement.md](ai/working-agreement.md) | ユーザーとAI Agentの協働方針 |
| Security | [development-guidelines.md](security/development-guidelines.md) | 公開リポジトリとCIの安全基準 |

## 文書の責務

- `README.md`：第三者向けのプロジェクト概要と利用方法
- `AGENTS.md`：AI Agentが必ず守る最上位ルールと入口
- `SECURITY.md`：公開リポジトリ利用者向けのセキュリティポリシー
- `docs/architecture/`：現在の構成
- `docs/design/`：個別機能の設計
- `docs/architecture/decisions/`：重要な設計判断（ADR）
- `docs/development/`：開発プロセスと完了条件
- `docs/ai/`：AI Agentの作業方針と活動記録

アプリ実装の開始後は、変更に関係する正本を同じIssueまたはPRで更新します。
