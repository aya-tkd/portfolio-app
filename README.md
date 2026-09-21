# 外来フロー管理システム（ポートフォリオ・学習用）

医療機関における患者の予約から外来受付、診察待ち、呼び出し、会計完了までの患者導線を管理する、ポートフォリオ・学習用のWebシステムです。

## 目的

実際の医療業務を完全に再現することではなく、外来フローを題材にRails/VueによるWeb開発を学習・提示することを目的とします。

- 業務フローと状態遷移のモデル化
- Web画面とデータフローの設計
- Rails、Vue、JavaScriptを使ったWeb開発
- SQLiteを使ったデータ管理
- テスト・ビルド確認とIssueベース開発
- AI Agentと人間の協働による開発

## AIを活用した開発プロセス

このリポジトリでは、業務要件、受入条件、変更範囲、公開・セキュリティに関する判断を人が担います。AIエージェントは実装、テスト、レビュー補助に活用し、実装ルール、テンプレート、Issue運用、人による確認工程の中で扱います。外来フローは、このWeb開発とAI協働の進め方を検証する題材であり、本番医療システムの再現や公開運用を目的としません。役割分担と判断基準は[AIとの協働方針](docs/ai/working-agreement.md)、[Issue中心の開発フロー](docs/development/issue-workflow.md)、[開発ルール](AGENTS.md)に記載しています。

## 想定する基本フロー

```text
患者Web予約 / 電話予約
        ↓
来院・外来受付
        ↓
診察待ち
        ↓
診察呼び出し
        ↓
診察
        ↓
会計待ち
        ↓
会計呼び出し
        ↓
会計完了
```

## 想定する利用者

- 患者
- 受付スタッフ
- 診察担当者
- 会計担当者
- システム管理者

## 対象外

電子カルテ、診療記録、診断支援、レセプト・保険請求、実際の決済、通知サービス、本番医療機関での利用は対象外です。医療上の判断には使用せず、開発データには実在患者の情報を使用しません。

## 現在の状態

このREADMEは、閲覧しているブランチの実装範囲を示します。PRブランチの内容はレビュー対象であり、受入・mergeの状態は[GitHub Project](https://github.com/users/aya-tkd/projects/2)と各PRを参照してください。

| 機能 | このブランチでできること | 画面 | 関連Issue |
|---|---|---|---|
| 外来一覧 | 日付・科・複数進捗検索、設備子行の開閉、呼出・診察開始/終了・設備実施、会計待ち判定 | `/outpatients` | [#38](https://github.com/aya-tkd/portfolio-app/issues/38) |
| マスタ設定 | 外来一覧から患者・診療科・職種・ユーザーを検索し、選択した登録・編集フォームへ遷移 | `/outpatients` の「マスタ設定」 | [#48](https://github.com/aya-tkd/portfolio-app/issues/48) |
| 患者マスタ | 新規登録・編集・SQLite保存 | `/` | [#1](https://github.com/aya-tkd/portfolio-app/issues/1) |
| 患者検索 | 患者番号の完全一致、氏名・カナ氏名の部分一致、選択患者の編集起動 | `/patients` | [#33](https://github.com/aya-tkd/portfolio-app/issues/33) |
| 外来受付 | 患者検索からの予約採用・予約なし受付、有効な医師ユーザーの選択、診察に付随する設備予約の引継ぎ、受付No.発番 | `/receptions/new?patient_id=<患者ID>` | [#43](https://github.com/aya-tkd/portfolio-app/issues/43) / [#56](https://github.com/aya-tkd/portfolio-app/issues/56) |
| 診療科マスタ | 新規登録・編集・SQLite保存 | `/masters/departments` | [#14](https://github.com/aya-tkd/portfolio-app/issues/14) |
| 職種マスタ | 新規登録・編集・SQLite保存、受付担当医区分の設定 | `/masters/occupations` | [#15](https://github.com/aya-tkd/portfolio-app/issues/15) / [#56](https://github.com/aya-tkd/portfolio-app/issues/56) |
| ユーザーマスタ | ID・氏名／カナ・診療科・職種で検索、共通様式のフォームで登録・編集・SQLite保存 | `/outpatients` の「マスタ設定」 | [#16](https://github.com/aya-tkd/portfolio-app/issues/16) |
| DB確認 | 読み取り専用SQL・ページ送り・スキーマ表示 | `/tools/sql` | [#1](https://github.com/aya-tkd/portfolio-app/issues/1) |

VueからRails APIを呼び、SQLiteへ保存します。外来一覧は予約・受付を読み取り、診察と設備の進捗を更新できます。外来一覧のマスタ設定では患者・診療科・職種・ユーザーを検索して登録・編集できます。予約登録、会計処理、専用設備実施一覧は未実装です。ローカル・架空データ限定で、認証・認可、ログイン、本番利用、外部公開には対応していません。

現在地の更新規約は[開発フロー](docs/development/issue-workflow.md#readmeと現在地の更新)、学習の進捗は[技術理解プロファイル](docs/learning/user-technical-profile.md)を参照してください。

## ローカル起動（PowerShell）

検証環境：Ruby 4.0.6、Rails 8.1.3.1、Node.js 22.17.0、npm 10.9.2。Rubyのネイティブ拡張ビルド環境が必要です。依存バージョンはGemfile.lock/package-lock.jsonに固定します。

```powershell
npm ci
Set-Location backend
bundle install
bundle exec ruby bin/rails db:prepare
bundle exec ruby bin/rails server -b 127.0.0.1 -p 3000
```

別ターミナルをリポジトリ直下で開き、`npm run dev`を実行し、[患者画面](http://127.0.0.1:5173/)を開きます。「新規」で登録し、登録後は自動設定された内部IDで「編集」を開けます。直URLは`/patients/new`、`/patients/<内部ID>/edit`です。終了は各ターミナルでCtrl+C。

SQLiteサーバーの別途インストールは不要です。Gemがドライバを提供し、`db:prepare`が`backend/storage/`内にDBを作ります。`backend/config/database.example.yml`は名前にexampleを含みますが、本アプリが実際に読み込む設定です。コピー・秘密情報の設定は不要です。DB・ログ・ローカルセッション用秘密値・ビルド出力はGit対象外です。

## 検証

外来一覧の受入データは、`backend`で `bundle exec ruby bin/rails db:seed` を実行して当日の架空セットを追加します。同日の再実行は既存の進捗を初期化しません。[外来一覧](http://127.0.0.1:5173/outpatients)で設備行を開閉し、次の操作を試せます。呼出は状態の記録のみで音声通知はありません。詳細は[外来設計](docs/design/outpatient/outpatient-list.md)を参照してください。

以下はリポジトリ直下から実行します（すでにbackendにいる場合は最初の移動を省略）。

```powershell
Set-Location backend
bundle exec ruby bin/rails test
Set-Location ..
npm test
npm run build
npx playwright install chromium
# 上記のRailsとViteが起動中の状態で実行
npx playwright test
```

Railsテストは専用の`backend/storage/test.sqlite3`を使用します。ブラウザテストは起動中の開発DBへ明示的な架空患者を作成します。実在データを入れないでください。スクリーンショット・失敗証跡は`tmp/`に保存します。`npm run build`は配信用ファイルの生成確認であり、外部公開やRailsからの本番配信は実装していません。

## DBの内容を画面で確認

ローカル起動後、[DB確認（SQL）](http://127.0.0.1:5173/tools/sql)を開いて「実行」を押すと患者テーブルを表示します。SQLは編集可能で、200行ずつページ送りできます。左側の分類別テーブル名をダブルクリックすると列・型を確認できます。読み取り専用・1文ずつで、UPDATE/DELETEなどには対応しません。患者画面からも別タブで開けます。

## コードを読む入口

[フォルダ構成と業務モデルの境界](docs/architecture/repository-structure.md)でツリーを確認できます。`frontend/`が画面、`backend/`がRails、`e2e/`が両者を通すテストです。

Web初学者向けの[ファイルと処理の読み方](docs/learning/patient-form-walkthrough.md)から読むのがおすすめです。[画面設計](docs/design/patient/patient-form.md)、[テーブル設計](docs/design/data-model/mst_patients.md)、[コメントの共通ルール](docs/development/code-readability.md)も参照できます。

詳細は[プロジェクト要件](docs/project/product-requirements.md)と[ドキュメント一覧](docs/INDEX.md)を参照してください。
