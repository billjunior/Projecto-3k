class Tenant < ApplicationRecord
  # Active Storage for logo
  has_one_attached :logo

  # Associations
  has_many :users, dependent: :destroy
  has_one :company_setting, dependent: :destroy

  # Enums
  enum status: { active: 0, expired: 1, suspended: 2 }

  # Validations
  validates :name, presence: true
  validates :subdomain, presence: true, uniqueness: true
  validates :status, presence: true

  # Scopes
  scope :active_subscriptions, -> { where(status: :active) }
  scope :expired_subscriptions, -> { where(status: :expired) }
  scope :expiring_soon, -> {
    where('subscription_end BETWEEN ? AND ?', Date.today, Date.today + 15.days)
  }

  # Instance methods
  def active?
    active_status = status == 'active'
    not_expired = subscription_end.nil? || subscription_end >= Date.today
    active_status && not_expired
  end

  def expired?
    subscription_end.present? && subscription_end < Date.today
  end

  def days_until_expiration
    return nil if subscription_end.nil?
    (subscription_end - Date.today).to_i
  end

  def expiring_soon?
    days = days_until_expiration
    days.present? && days > 0 && days <= 15
  end
end
