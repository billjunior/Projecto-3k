class TrainingCourse < ApplicationRecord
  include TenantScoped

  # Enums
  enum payment_type: { manual: 0, bank_transfer: 1 }
  enum status: { active: 0, completed: 1, cancelled: 2 }

  # Validations
  validates :student_name, presence: true
  validates :module_name, presence: true
  validates :total_value, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :amount_paid, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :training_days, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :start_date, presence: true
  validates :payment_type, presence: true

  # Scopes
  scope :for_month, ->(month, year) { where('EXTRACT(MONTH FROM start_date) = ? AND EXTRACT(YEAR FROM start_date) = ?', month, year) }
  scope :by_date, -> { order(start_date: :desc) }

  # Methods
  def balance
    (total_value || 0) - (amount_paid || 0)
  end

  def payment_percentage
    return 0 if total_value.nil? || total_value.zero?
    ((amount_paid || 0) / total_value * 100).round(1)
  end
end
