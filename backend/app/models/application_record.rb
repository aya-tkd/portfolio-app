# DBモデルの共通の親。自身のテーブルは持たず、Patientなどが継承する。
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end
