class CompanySetting < ApplicationRecord
  acts_as_tenant :tenant

  # Associations
  belongs_to :tenant
  has_one_attached :logo

  # Callbacks
  after_initialize :ensure_arrays

  # Validations
  validates :company_name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }
  validates :director_general_email, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }
  validates :financial_director_email, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }

  # Helper method for missing items recipients
  def missing_items_recipients
    [director_general_email, financial_director_email].compact.reject(&:blank?)
  end

  private

  def ensure_arrays
    self.phones ||= []
    self.emails ||= []
    self.ibans ||= []
    self.bank_accounts ||= []
  end
end
