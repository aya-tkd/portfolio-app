# フォルダ構成と業務モデルの境界

Issue #1のユーザー指示により、FE/BEを明確に分け、業務機能から探せる構成へ変更した。画面・API・DB契約は変更しない。

## 現在のツリー

```text
frontend/
  src/
    App.vue                       アプリ全体の入口
    main.js                       VueをHTMLに取り付ける起動処理
    features/patients/
      components/
        PatientWorkspace.vue      患者機能の呼び出し元
        PatientForm.vue           患者登録・編集フォーム
      api.js                      患者固有のAPI契約
    features/administration/departments/
      components/
        DepartmentWorkspace.vue   診療科機能の呼び出し元
        DepartmentForm.vue        診療科登録・編集フォーム
      api.js                      診療科固有のAPI契約
    shared/
      api/http.js                 業務非依存のHTTP通信
      styles/style.css            共通の業務UIスタイル
  test/                           フロントエンドの単体テスト
  index.html                      ブラウザが読むHTMLの入口
backend/
  app/
    controllers/api/              HTTP受付・応答（患者・診療科API）
    models/                       患者・診療科の永続化・検証
  config/                         Rails設定・ルート
  db/                             migration・schema
  test/                           Railsのモデル・APIテスト
  bin/                            Railsコマンドの入口
  Gemfile / Gemfile.lock           Ruby依存関係
  Rakefile / config.ru             Railsタスク・HTTPサーバーの入口
  storage/ log/ tmp/               実行時データ（Git対象外）
e2e/                              FEからBEまで通すブラウザテスト
docs/                             設計・ルール・学習資料
package.json / package-lock.json   FEとE2E共用のNodeツール管理
vite.config.js                    FE開発サーバー・ビルド設定
playwright.config.js              E2Eの実行設定
```

`test`はバックエンド本体ではない。本体は`backend/app`で、`backend/test`はその検証。Railsコマンドはbackendで、npm・Playwrightはリポジトリ直下で実行する。

FEは機能→責務で整理する。予約・受付が増えた時点で`features/reservations`、`features/reception`を追加する。BEはRailsの責務別配置を維持し、複雑化した領域に名前空間を加える。例：`app/services/reception/check_in.rb`の`Reception::CheckIn`。これは将来の例で、空フォルダや未使用クラスは作らない。

## Modelを無条件に共通化しない

「同じ実在の患者を扱う」ことと「同じモデル・ルールを共有する」ことは別。DDDでは、意味とルールが一貫する境界（Bounded Context）ごとに同じ対象の異なるモデルを持ち得る。ただし、画面・機能・フォルダが一つ増えるたびに必ず別Contextになるわけではない。

現在の`backend/app/models/patient.rb`は、患者登録・編集が所有する**患者基本情報の永続化モデル**。全領域の患者概念を保証したShared Modelではない。Rails標準のmodels直下に置くことは共通ドメインモデルと宣言することでもない。

将来、例えば次を比較する（現段階ではモデル分割を実装しない）。

| 必要な違い | 検討する構成 |
|---|---|
| 取得・表示項目が違うだけ | クエリやDTO/読み取り用データで必要項目に限定 |
| 予約枠・取消期限など予約固有のルール | 予約のモデル/処理が所有し、必要な患者識別子・情報を受け取る |
| 来院・受付状態など受付固有のルール | 受付のモデル/処理が所有し、基本情報の更新処理へ混ぜない |
| 同じ「患者」の意味・不変条件・変更責任が異なる | 境界別モデルと明示的な変換・連携を検討 |

別モデルは別テーブルを必須とせず、同じテーブルだから同じドメインモデルとも限らない。永続化の共有と業務ルールの共有を別々に判断する。ただし複数モデルが同じ列へ無秩序に書き込まないよう、書き込みの責任とデータの正本を定める。

「派生」は必ずしもクラス継承を意味しない。単に用途が違う場合、`Patient`を継承して責務を増やすより、識別子による参照・合成・DTO・別モデルが適する場合がある。RailsのActiveRecord継承（STI）を業務境界の表現として安易に採用しない。

Sharedへ置くのは、意味・変更理由・所有責任を共有できると確認したものに限る。未来の完全保証はできないため、分離の余地と変更時の判断基準を残す。今回は共通HTTP処理とUIスタイルをSharedへ置き、患者のAPI契約・画面・業務ルールは置かない。

参照：[Bounded Context（Martin Fowler）](https://martinfowler.com/bliki/BoundedContext.html)、[Railsの配置と名前空間](https://guides.rubyonrails.org/autoloading_and_reloading_constants.html)。
