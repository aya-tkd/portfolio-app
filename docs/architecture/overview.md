# Architecture Overview

## 現在の状態

Issue #1の承認済み設計（v0.3＋v0.4追補）に基づき、患者登録・編集をVue＋Rails＋SQLiteで実装しています。患者一覧・予約以降は未実装です。公開リポジトリですが、アプリ自体はローカル・架空データ限定です。

## 構成方針

配置と業務モデルの所有境界は[フォルダ構成と業務モデルの境界](repository-structure.md)を参照する。FEは機能→責務、BEはRailsの責務別配置＋必要時に業務領域の名前空間とする。Patientを無条件のShared Modelとは位置付けない。

- ユーザーが理解できる最も単純な構成から開始する。
- 要件に必要な技術だけを採用する。
- 不要なマイクロサービス、DDD、CQRS、Repository Patternなどを先行導入しない。
- 構成を高度化する場合は、実際の問題、代替案、学習コスト、導入効果をADRに記録する。
- 初期段階では、1つの医療機関を対象とする単一Webアプリケーションとして構成する。
- 役割ごとの画面や機能は分けるが、別サービスへ分割する必要性が生じるまでは分割しない。

## 技術候補と選定方針

このポートフォリオでは、以下を学習・利用候補とします。

- Ruby on Rails
- Node.js
- Vue
- JavaScript ES6+
- Bootstrap / Tailwind CSS

ただし、システム要件に不要な技術を無理に採用しません。BootstrapとTailwind CSSについても、要件、学習難易度、他の案件への汎用性を踏まえて選択します。

採用技術と各技術の役割分担は、要件を踏まえてユーザーへ説明し、合意を得てから確定します。決定した内容は本書と必要なADRへ反映します。

## データベース方針

SQLとRDBの基本は既習であり、今回の主な学習対象はWeb開発です。そのため、業務フローとデータフローを実装・理解することを優先し、初期データベースにはSQLiteを採用します。

- Railsを採用する場合はActiveRecordとmigrationを利用する
- 予約、受付、待ち行列、呼び出し、会計状態の流れを扱う
- DB製品固有の高度な機能は初期スコープに含めない
- PostgreSQLへの移行は、同時アクセス、デプロイ先、運用要件などの必要性が生じた場合に検討する

## Issue #1で採用した構成

- Vue 3：ブラウザの画面・入力・非同期状態管理。患者フォームを親画面から呼び出すコンポーネントとして分離。
- Rails 8.1：HTTPルーティング、許可パラメータ、Modelの検証・保存、JSON応答。
- SQLite＋ActiveRecord：DBファイルの永続化とmigration。内部IDと表示Noを別カラムで保持。
- Bootstrap 5＋共通CSS：画面の基本スタイルと業務向け密度・色・文言の統一。
- Node.js＋Vite：Vueの開発・ビルド用。第二の業務バックエンドではない。現行Node 22.17で動くVite 6.4.3を固定。

ブラウザ → Vite（127.0.0.1:5173）→ `/api`プロキシ → Rails/Puma（127.0.0.1:3000）→ SQLite。プロキシはHostを保持し、ブラウザから同一オリジンで通信する。ログインなしだがRailsのCSRFトークン・Origin検証とサーバー側入力検証は維持する。development/test以外の起動は拒否する。CORS全許可や外部公開設定は追加しない。

Ruby 4.0.6環境で依存関係を検証した。JSON 3とRailsの解析処理に互換性問題を確認したためGemfileでJSON 2系に制限し、解決版をlockfileへ固定した。具体的な起動方法は[README](../../README.md)、画面契約は[患者登録・編集](../design/patient/patient-form.md)を参照する。

実装時の参照：[Rails Security Guide](https://guides.rubyonrails.org/security.html)、[Vite server options](https://vite.dev/config/server-options)、[Vue form bindings](https://vuejs.org/guide/essentials/forms.html)。

## 将来の記載内容

- 実行環境と主要コンポーネント
- コンポーネント間の責務と通信
- データストアとデータフロー
- 認証・認可境界
- 外部サービスと依存関係
- 運用・監視・CI/CD
