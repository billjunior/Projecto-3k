class Contact < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant :tenant

  # Associations
  belongs_to :contactable, polymorphic: true
  belongs_to :tenant

  # Validations
  validates :name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validate :only_one_primary_per_contactable

  # Scopes
  scope :primary_contacts, -> { where(primary: true) }
  scope :secondary_contacts, -> { where(primary: false) }
  scope :recent, -> { order(created_at: :desc) }

  # Callbacks
  before_validation :set_first_as_primary, on: :create

  private

  def only_one_primary_per_contactable
    if primary? && contactable.present?
      existing_primary = contactable.contacts.where(primary: true).where.not(id: id).exists?
      if existing_primary
        errors.add(:primary, 'já existe um contacto principal para este registo')
      end
    end
  end

  def set_first_as_primary
    if contactable.present? && contactable.contacts.empty?
      self.primary = true
    end
  end
end
