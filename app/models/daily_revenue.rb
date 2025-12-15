class DailyRevenue < ApplicationRecord
  include TenantScoped
  include Auditable

  # Enums
  enum payment_type: { manual: 0, bank_transfer: 1 }

  # Validations
  validates :date, presence: true
  validates :description, presence: true
  validates :quantity, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :unit_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :entry, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :exit, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :payment_type, presence: true

  # Callbacks
  before_save :calculate_total

  # Scopes
  scope :for_month, ->(month, year) { where('EXTRACT(MONTH FROM date) = ? AND EXTRACT(YEAR FROM date) = ?', month, year) }
  scope :with_entries, -> { where('entry > 0') }
  scope :with_exits, -> { where('exit > 0') }
  scope :by_date, -> { order(date: :desc) }

  private

  def calculate_total
    self.total = (entry || 0) - (exit || 0)
  end
end
