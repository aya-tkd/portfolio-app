# mst_occupations

- 親Issue：#15
- 設計Sub-issue：#20
- migration：[20260912000100_create_occupations.rb](../../../backend/db/migrate/20260912000100_create_occupations.rb)、[20260921000100_add_doctor_master_references.rb](../../../backend/db/migrate/20260921000100_add_doctor_master_references.rb)
- Rubyモデル：`Occupation`（API：`/api/occupations`）
- 関連画面：[職種マスタ：登録・編集](../administration/occupation-form.md)

## 目的・業務上の意味

職員の職種を管理するマスタである。将来の権限設計やスタッフ情報から参照する可能性があるが、現時点では職種と権限を直接結び付けない。

## カラム

| カラム | 型 | NULL | 初期値 | 制約・バリデーション | 業務上の意味 |
|---|---|---:|---|---|---|
| id | integer | 不可 | 自動採番 | 主キー、更新不可 | システム内部ID |
| name | string | 不可 | — | 1〜100文字、DB CHECK | 職種名 |
| display_order | integer | 不可 | — | 1以上の整数、DB CHECK | 画面などでの並び順 |
| active | boolean | 不可 | `true` | true / false、DB CHECK | 利用状態 |
| occupation_code | string | 不可 | `other` | `physician` / `other`、DB CHECK | `physician`は受付で担当医として選択可能にする分類。認可権限・資格・勤務可否ではない |
| created_at / updated_at | datetime | 不可 | Rails | — | 登録・更新日時 |

## キー・関連・制約

- 主キーは`id`。SQLiteが自動採番し、Railsモデルでも更新不可にする。
- `mst_users.occupation_id`から参照される。受付候補は、有効なユーザーと有効な職種のうち`occupation_code = physician`を満たすものに限定する。
- 職種名の一意制約は設けない。同名を許容するかの業務判断は、利用者・権限設計を導入する際に改めて決める。
- 削除は実装しない。利用状態は登録・編集画面で変更できる。

## CRUDする画面・操作

| 画面・操作設計 | Create | Read | Update | Delete | 備考 |
|---|---:|---:|---:|---:|---|
| [職種マスタ：登録・編集](../administration/occupation-form.md) | ○ | ○ | ○ | — | ID指定で編集対象を開く |

## 変更履歴

職種は「職位」ではなく、職員カテゴリとして定義した。Issue #56で受付担当医の業務分類を`occupation_code`として追加した。既存データは名称から推測せず`other`へ移行し、管理者が明示的に設定する。議論と承認記録は設計Sub-issue #20および#57を参照する。
