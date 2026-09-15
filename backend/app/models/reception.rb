# 来院・診察の正本。Queryと進捗更新Serviceから使う。
# 表示上の会計待ちは保存せず、設備の完了条件から導出する。
class Reception < ApplicationRecord
  self.table_name = "trn_receptions"
  belongs_to :patient
  belongs_to :department
  has_many :appointments, dependent: :restrict_with_exception
  has_many :equipment_executions, dependent: :restrict_with_exception
  validates :received_at, presence: true
  validates :business_kind, inclusion: { in: %w[consultation equipment] }
  validates :consultation_status, inclusion: { in: %w[received called consulting consulted] }
  validates :doctor_name, length: { maximum: 100 }
  validates :reception_number, presence: true, uniqueness: true
  before_validation :temporary_number, on: :create
  after_create :assign_number
  attr_readonly :reception_number

  def display_status
    return "paid" if paid_at
    active = equipment_executions.reject(&:cancelled_at)
    complete = active.all?(&:completed_at)
    return (active.any? && complete ? "billing_wait" : "execution_wait") if business_kind == "equipment"
    return (complete ? "billing_wait" : "equipment_wait") if consultation_status == "consulted"
    consultation_status
  end

  private

  def temporary_number
    self.reception_number ||= "pending-#{SecureRandom.uuid}"
  end

  def assign_number
    self.class.where(id: id).update_all(reception_number: id.to_s)
    reload
  end
end
