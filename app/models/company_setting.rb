class CompanySetting < ApplicationRecord
  acts_as_tenant :tenant

  # Associations
  belongs_to :tenant
  has_one_attached :logo

  # Callbacks
  after_initialize :ensure_arrays
  after_initialize :set_default_margin, if: :new_record?

  # Validations
  validates :company_name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }
  validates :director_general_email, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }
  validates :financial_director_email, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }
  validates :default_profit_margin, presence: true,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999.99 }

  # Helper method for missing items recipients
  def missing_items_recipients
    [director_general_email, financial_director_email].compact.reject(&:blank?)
  end

  # Convert profit margin percentage to decimal for calculations
  def profit_margin_decimal
    (default_profit_margin || 65.0) / 100.0
  end

  private

  def ensure_arrays
    self.phones ||= []
    self.emails ||= []
    self.ibans ||= []
    self.bank_accounts ||= []
  end

  def set_default_margin
    self.default_profit_margin ||= 65.0
  end
end
