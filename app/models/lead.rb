class Lead < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant :tenant

  # Associations
  belongs_to :tenant
  belongs_to :assigned_to_user, class_name: 'User', optional: true
  belongs_to :converted_to_customer, class_name: 'Customer', optional: true

  # Enums
  enum classification: { hot: 0, warm: 1, cold: 2 }
  enum contact_source: {
    whatsapp: 0,
    telefone: 1,
    instagram: 2,
    facebook: 3,
    twitter: 4,
    outro: 5
  }

  # Validations
  validates :name, presence: true
  validates :classification, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }

  # Scopes
  scope :not_converted, -> { where(converted_to_customer_id: nil) }
  scope :converted, -> { where.not(converted_to_customer_id: nil) }
  scope :by_classification, ->(classification) { where(classification: classification) }
  scope :recent, -> { order(created_at: :desc) }

  # Instance methods
  def converted?
    converted_to_customer_id.present?
  end

  def convert_to_customer!(attributes = {})
    return converted_to_customer if converted?

    customer = Customer.create!({
      tenant: tenant,
      name: name,
      email: email,
      phone: phone,
      customer_type: 'particular',
      notes: "Convertido de lead: #{notes}"
    }.merge(attributes))

    update!(
      converted_to_customer: customer,
      converted_at: Time.current
    )

    customer
  end
end
