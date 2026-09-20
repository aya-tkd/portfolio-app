# Issue #48 学習記録

関連：[親Issue](https://github.com/aya-tkd/portfolio-app/issues/48)、[設計](https://github.com/aya-tkd/portfolio-app/issues/49)、[テスト](https://github.com/aya-tkd/portfolio-app/issues/50)。

今回の概念は、Vueの親コンポーネントが表示状態を持ち、子コンポーネントが `props` と `emit` で一覧とフォームを往復する方法である。外来一覧はダイアログを開閉するだけで検索状態を保持し、マスタ設定ワークスペースが対象マスタ・選択行・一覧／フォーム表示を担当する。

| 観点 | 観測と評価 |
|---|---|
| Vueと画面処理・APIの分担 | L2を維持。設計承認と実装結果はあるが、ユーザー自身が親子状態・emitの流れを説明した証拠は未取得。 |
| HTTPメソッド | L1を維持。GET検索と既存POST/PATCH保存の使い分けを実装したが、理解度の更新根拠にはしない。 |
| Vite→Railsルート→Controller | L2を維持。`api.js`、routes、Controllerの具体的な経路を設計Docに記録したが、自力説明の観測は未取得。 |

## 実コードを読む順番

1. `frontend/src/features/outpatients/components/OutpatientListWorkspace.vue`：外来一覧を残したまま「マスタ設定」ダイアログを開閉する。
2. `frontend/src/features/administration/components/MasterSettingsWorkspace.vue`：マスタ切替、検索、選択行、一覧とフォームの切替を保持する。
3. `frontend/src/features/administration/*/api.js` と `features/patients/api.js`：検索条件をGET URLへ変換する。
4. `backend/config/routes.rb` → `Api::DepartmentsController` / `Api::OccupationsController`：一覧リクエストを受け、Active Recordで部分一致・利用状態を絞り込む。
5. 各Formは保存成功時に `close` をemitし、ワークスペースが再検索して一覧表示を同期する。

C#の画面イベントに近いのは `@click` と `@close` だが、Vueでは親が子へ値を渡すのがprops、子が親へ結果を返すのがemitである。HTTP GETは読取専用の検索、POST/PATCHは既存フォームの保存に使う。次のレビューで、選択した診療科をフォームに渡して保存後に再検索する経路を実コードと対応付けて説明する。
