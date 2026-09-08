# 外来フロー管理システム（ポートフォリオ・学習用）

医療機関における患者の予約から外来受付、診察待ち、呼び出し、会計完了までの患者導線を管理する、ポートフォリオ・学習用のWebシステムです。

## 目的

実際の医療業務を完全に再現することではなく、Web開発とAI Agentを活用した開発プロセスを学習・提示することを目的とします。

- 業務フローと状態遷移のモデル化
- Web画面とデータフローの設計
- Rails、Vue、JavaScriptを候補としたWeb開発
- SQLiteを使ったデータ管理
- テスト、CI/CD、Issueベース開発
- AI Agentと人間の協働による開発

## 基本フロー

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

Issue #1で患者登録・編集を実装しています。Vueの共通ダイアログからRails APIを呼び、SQLiteへ保存します。患者一覧・予約以降の導線は未実装です。ローカル・架空データ限定、ログインなし。本番利用・外部公開には対応していません。

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
