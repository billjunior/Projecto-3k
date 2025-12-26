class Communication < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant :tenant

  # Associations
  belongs_to :communicable, polymorphic: true
  belongs_to :tenant
  belongs_to :created_by_user, class_name: 'User'

  # Enums
  enum communication_type: {
    email: 0,
    call: 1,
    meeting: 2,
    note: 3,
    whatsapp: 4
  }

  # Validations
  validates :communication_type, presence: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :completed, -> { where.not(completed_at: nil) }
  scope :pending, -> { where(completed_at: nil) }
  scope :by_type, ->(type) { where(communication_type: type) }

  # Instance methods
  def completed?
    completed_at.present?
  end

  def mark_as_completed!
    update!(completed_at: Time.current)
  end

  def communication_type_label
    case communication_type
    when 'email' then 'Email'
    when 'call' then 'Chamada'
    when 'meeting' then 'Reunião'
    when 'note' then 'Nota'
    when 'whatsapp' then 'WhatsApp'
    else communication_type&.capitalize
    end
  end
end
