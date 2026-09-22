# mst_users

架空スタッフの基本情報を保存する。認証資格情報は保存しない。

| カラム | 意味 |
|---|---|
| id | SQLite自動採番の内部ユーザーID。更新不可 |
| last_name / first_name | 必須の氏名、各100文字以内 |
| last_name_kana / first_name_kana | 必須のカナ氏名、各100文字以内 |
| department_id | 任意。mst_departmentsへの外部キー |
| occupation_id | 任意。mst_occupationsへの外部キー |
| active | 必須。利用中／停止中 |

診療科・職種は有効な既存マスタだけを関連付ける。ユーザー自身と職種が有効で、職種の`occupation_code`が`physician`のときだけ、[外来受付](../outpatient/reception.md)の担当医候補になる。受付行では、対象診療科と`department_id`が一致するユーザー、または`department_id`がNULLのユーザーだけを候補にする。これは職種・主担当診療科による最小の選択条件であり、複数診療科兼務、削除・履歴・認証認可は対象外。
