# 患者フォームから読むWebアプリ入門

今回はVue＋Rails＋SQLite。全部のファイルを一度に理解する必要はありません。まず「登録を押したとき」に関わる6ファイルを順に読みます。

## 最初に読むファイル

| 順 | ファイル | 役割・C#経験との接点 |
|---|---|---|
| 1 | [PatientWorkspace.vue](../../frontend/src/features/patients/components/PatientWorkspace.vue) | 呼び出し元画面。WinFormsの親フォームに近い役割 |
| 2 | [PatientForm.vue](../../frontend/src/features/patients/components/PatientForm.vue) | 入力ダイアログ。値・送信中・エラー表示を管理 |
| 3 | [api.js](../../frontend/src/features/patients/api.js) | HTTP通信の窓口。HttpClientを使う処理に近い |
| 4 | [routes.rb](../../backend/config/routes.rb) | URLとHTTPメソッドをControllerの処理へ振り分ける表 |
| 5 | [patients_controller.rb](../../backend/app/controllers/api/patients_controller.rb) | 入力を受け、Modelを呼び、HTTP応答を返す。ASP.NET CoreのControllerに近い |
| 6 | [patient.rb](../../backend/app/models/patient.rb) | 入力検証とpatientsテーブルへの保存。ActiveRecordはEF Coreと同じくDBアクセスを助けるが、クラス自体に保存操作を持つ |

Rubyのコードはサーバー側、VueのJavaScriptはブラウザ側で動きます。同じPCで起動していても別の実行環境です。VueからRubyのメソッドを直接呼ぶのではなく、HTTPでデータを送ります。

## `.vue`を読む

`PatientForm.vue`は画面部品を一つのファイルにまとめたものです。

- `<script setup>`：JavaScriptの処理。入力値やイベント処理を定義します。
- `<template>`：HTMLにVueの記法を加えた画面定義。ブラウザが直接`.vue`を理解するわけではなく、ViteがJavaScriptへ変換します。
- CSS：今回は共通化のため[style.css](../../frontend/src/shared/styles/style.css)へ分離しました。Bootstrapを読み込んだ後で色・密度・ボタン配置を揃えます。

`reactive({...})`は入力値のまとまりです。`v-model="values.last_name"`で入力欄とその値を結びます。ユーザーが姓を入力すると値が更新され、プログラムから値を変更すれば画面にも反映されます。

`ref(false)`は単一の状態を保持します。JavaScriptでは`busy.value`、templateでは`busy`と書きます。`v-if`は条件に応じた表示、`:disabled`は状態に応じた操作禁止、`@click`はクリック時の処理です。

`props`は親から渡される入力、`emit`は親へ知らせるイベントです。今回、親は内部IDを渡し、子は保存結果を`close`イベントで返します。

## 「登録」を押してから戻るまで

1. `PatientForm.vue`の`@submit.prevent="save"`が実行されます。`.prevent`はブラウザ標準のフォーム送信・ページ遷移を止め、JavaScript側で通信する指定です。
2. `save()`は送信中状態にして二重クリックを抑止し、`api.js`の`savePatient()`へ入力値を渡します。生年月日の空文字は`null`へ変換します。
3. `savePatient()`はRailsからCSRFトークンを取得し、新規なら`POST /api/patients`、編集なら`PATCH /api/patients/:id`へJSONを送ります。`await`は通信結果を待つ記法で、ブラウザ全体を停止するものではありません。
4. `routes.rb`が`POST`を`create`、`PATCH`を`update`へ振り分けます。URLの`:id`は表示Noではなく内部IDです。
5. `PatientsController`の`patient_params`が入力項目を限定します。画面を改造して内部IDや表示Noを送られても、それらは更新対象にしません。
6. `Patient#save`が姓名・カナ・日付・性別を検証します。成功すればActiveRecordがSQLを実行してSQLiteへ保存します。番号の初期設定も同じトランザクション内で行います。
7. Controllerは成功なら患者データをJSONで返します。新規はHTTP 201、更新は200。入力不正は422と項目別エラーです。
8. Vueは成功応答を受けて親へ結果を返し、ダイアログを閉じます。親は表示Noを通知し、次回編集用に内部IDを保持します。

入力不正ならダイアログを閉じず、値とエラーを表示します。通信が切れた場合は「サーバーでは保存済みだが返事だけ届かなかった」可能性があるため、自動再送しません。クリック禁止だけで重複登録を完全防止できるとは限りません。

## 設定ファイルは何をするのか

| ファイル | 読まれる場面・役割 |
|---|---|
| [frontend/index.html](../../frontend/index.html) | ブラウザが最初に読むHTML。Vueを置く`#app`を用意 |
| [main.js](../../frontend/src/main.js) | 共通CSSを読み、`App.vue`を`#app`に取り付ける入口 |
| [vite.config.js](../../vite.config.js) | Vueの変換と開発サーバー設定。`/api`だけRailsへ転送 |
| [package.json](../../package.json) | JavaScript側の依存ライブラリと`npm run`コマンド |
| [Gemfile](../../backend/Gemfile) | Ruby側の依存ライブラリ。lockfileが解決済みの版を固定 |
| [boot.rb](../../backend/config/boot.rb) | BundlerでRubyの依存関係を読み込む準備 |
| [application.rb](../../backend/config/application.rb) | Rails全体の共通設定。DB、タイムゾーン、セッション等 |
| [environment.rb](../../backend/config/environment.rb) | Railsアプリを初期化する入口 |
| [development.rb](../../backend/config/environments/development.rb) | 開発時だけの設定。コード変更時の再読込等 |
| [test.rb](../../backend/config/environments/test.rb) | 自動テスト時だけの設定。テストでもCSRF検証を有効化 |
| [puma.rb](../../backend/config/puma.rb) | HTTPを受け付けるRubyサーバーの待受・スレッド設定 |
| [database.example.yml](../../backend/config/database.example.yml) | 実際に読み込むSQLite設定。開発用とテスト用DBを分離 |
| [migration](../../backend/db/migrate/20260907000100_create_patients.rb) | テーブル・インデックスを作る変更手順 |
| [schema.rb](../../backend/db/schema.rb) | migrationからRailsが生成した現在のDB構造。通常は直接編集しない |

開発中はブラウザが`127.0.0.1:5173`へアクセスします。Viteは画面を配信し、`/api`への通信は`127.0.0.1:3000`のRailsへ転送します。Node.jsはこの開発・ビルド作業の実行役で、患者を保存する別の業務サーバーではありません。

## テストの読み方

- `backend/test/models/patient_test.rb`：DB保存や入力制約を直接確認。
- `backend/test/controllers/patients_test.rb`：HTTP入力からJSON応答まで、Rails内を通して確認。
- `frontend/test/api.test.js`：通信結果を模擬してJavaScriptの扱いを確認。
- `e2e/patient.spec.js`：本物のブラウザで入力・登録・編集・エラー・フォーカスを確認。

次に読むなら、まず`PatientForm.vue`の`save()`と`PatientsController#create`を並べてください。「同じ処理の前半・後半」ですが、間にはHTTPという境界があります。
