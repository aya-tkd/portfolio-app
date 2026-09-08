# mst_patients

- 親Issue #1／設計Issue #2、承認版v0.4。
- [migration](../../../backend/db/migrate/20260907000100_create_patients.rb)
- [名称変更migration](../../../backend/db/migrate/20260908000100_rename_patients_to_mst_patients.rb)：PRレビュー中にユーザーが接頭辞方式を承認。既存データを保持してpatientsから改名する。
- RubyモデルはPatient、APIは/api/patientsのまま。self.table_nameで物理名を対応付ける。
- 利用画面：[患者登録・編集](../patient/patient-form.md)（Create/Read/Update、Deleteなし）

## 目的・カラム

予約・受付で将来参照する架空患者の基本情報。診療情報は保持しない。

| カラム | 型 | NULL | 制約・意味 |
|---|---|---|---|
| id | integer | 不可 | 自動採番PK。内部参照・APIの対象特定。変更不可 |
| patient_number | string | 不可 | UNIQUE。診察券・連携向けの表示No。初回idの十進文字列を設定、今回の編集では変更不可 |
| last_name / first_name | string | 不可 | 姓・名。各必須、100文字以内、空白のみ不可 |
| last_name_kana / first_name_kana | string | 不可 | セイ・メイ。各必須、100文字以内、許容カナ制約 |
| birth_date | date | 可 | 未入力NULL、入力時は実在日かつ未来日不可 |
| sex | string | 不可 | 初期値空文字＝未設定。male/female/other、DBのCHECK制約も適用 |
| created_at / updated_at | datetime | 不可 | Rails管理の作成・更新時刻。完全な変更監査ログではない |

## キー・整合性

主キーはid、表示Noに一意インデックス。現時点の外部キー・関連テーブルなし。将来の参照は表示Noでなくidを使う。表示Noは先頭ゼロや英字を将来扱えるよう文字列で独立保持する。連携用番号の変更・対応表は今回作らない。

新規保存ではbefore_createで一意な仮番号をセットし、INSERTでidが決まった後、after_createでidの文字列表記へ更新する。両方はActiveRecordの保存トランザクション内。番号確定に失敗すればINSERTもロールバックする。仮番号はcommitしない。将来任意の外部番号を取り込む際は初回採番との衝突方針を再設計する。

ModelのreadonlyとControllerの許可項目で番号の更新を防ぐ。DB管理者による直接SQLまで変更禁止を保証するものではない。姓名の長さ・カナ・日付の業務検証はModelが担当し、SQLiteのstring limitだけには依存しない。

モデル/APIテストで表示No重複拒否、idと異なる表示Noの取得、採番失敗のロールバック、日付NULL更新、番号変更不可を確認する。経緯は設計Issue #2・ログIssue #4に記録する。

改名の往復検証はbackendで `bundle exec ruby bin/rails runner test/support/verify_patient_table_rename.rb` を実行する。独立したメモリDBで初期migrationから構築し、改名・rollback・再適用後の行データ、表示Noの先頭ゼロ、一意インデックス、CHECK、Patientモデルの参照を確認する。既存CHECK名patients_sex_valuesは履歴上の名前として保持する。
