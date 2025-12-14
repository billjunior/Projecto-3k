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

  private

  def ensure_arrays
    self.phones ||= []
    self.emails ||= []
    self.ibans ||= []
    self.bank_accounts ||= []
  end
end
