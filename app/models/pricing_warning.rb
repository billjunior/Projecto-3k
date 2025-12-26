class PricingWarning < ApplicationRecord
  acts_as_tenant :tenant

  # Associations
  belongs_to :warnable, polymorphic: true
  belongs_to :created_by_user, class_name: 'User', optional: true

  # Validations
  validates :warning_type, presence: true,
            inclusion: { in: %w[below_margin high_discount] }

  # Scopes
  scope :below_margin, -> { where(warning_type: 'below_margin') }
  scope :high_discount, -> { where(warning_type: 'high_discount') }
  scope :unnotified, -> { where(director_notified: false) }
  scope :recent, -> { order(created_at: :desc) }

  # Helper methods
  def margin_gap
    return 0 if expected_margin.nil? || actual_margin.nil?
    expected_margin - actual_margin
  end

  def severity
    gap = margin_gap
    case gap
    when 0..5 then 'low'
    when 5..15 then 'medium'
    else 'high'
    end
  end
end
