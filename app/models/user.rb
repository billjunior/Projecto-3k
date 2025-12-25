class User < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant :tenant

  # Include default devise modules with security enhancements
  # :confirmable, :lockable, :timeoutable, :trackable for security
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable, :trackable

  # Associations
  belongs_to :tenant, optional: true  # Optional during transition period

  # Callbacks
  before_validation :set_default_role, on: :create
  before_validation :set_must_change_password, on: :create
  after_create :skip_confirmation_in_development

  # Enums
  # Roles: commercial (assistente comercial), cyber_tech (tecnico cyber cafe),
  # attendant (atendente), production (producao)
  enum role: { commercial: 0, cyber_tech: 1, attendant: 2, production: 3 }

  # Departments: financial (directora financeira), commercial_dept, technical_dept
  # Using _dept suffix to avoid conflict with role enum
  enum department: { financial: 0, commercial_dept: 1, technical_dept: 2 }

  # Validations
  validates :name, presence: true
  validates :role, presence: true

  # Scopes
  scope :active, -> { where(active: true) }
  scope :super_admins, -> { where(super_admin: true) }
  scope :admins, -> { where(admin: true) }
  scope :crm_users, -> { where.not(role: :cyber_tech) }
  scope :cyber_users, -> { where(role: :cyber_tech).or(where(super_admin: true)).or(where(admin: true)) }

  # Permission Helper Methods

  # Can access CRM main system?
  def can_access_crm?
    super_admin? || admin? || commercial? || attendant? || production?
  end

  # Can access Cyber Cafe?
  def can_access_cyber?
    super_admin? || admin? || cyber_tech?
  end

  # Role checks
  def commercial?
    role == 'commercial'
  end

  def cyber_tech?
    role == 'cyber_tech'
  end

  def attendant?
    role == 'attendant'
  end

  def production?
    role == 'production'
  end

  # Department checks
  def financial_director?
    admin? && department == 'financial'
  end

  def director?
    admin? && !financial_director?
  end

  # Admin checks
  def admin?
    admin == true
  end

  def super_admin?
    super_admin == true || financial_director?
  end

  # Full access check
  def full_access?
    super_admin? || admin?
  end

  # Can manage users?
  def can_manage_users?
    super_admin? || financial_director?
  end

  # Can view financial reports?
  def can_view_financial_reports?
    super_admin? || financial_director?
  end

  # Can manage cyber cafe?
  def can_manage_cyber?
    super_admin? || cyber_tech?
  end

  # Can reset passwords and block/unblock accounts?
  def can_manage_user_accounts?
    super_admin? || financial_director?
  end

  # Check if user is privileged (changes password in-app instead of email)
  def privileged_user?
    super_admin? || admin? || financial_director? || director?
  end

  # Check if password has expired (90 days)
  def password_expired?
    return true if password_changed_at.nil? # Never changed
    password_changed_at < 90.days.ago
  end

  # Check if needs to change password (first login or expired)
  def needs_password_change?
    must_change_password? || password_expired?
  end

  # Mark password as changed
  def mark_password_changed!
    update_columns(must_change_password: false, password_changed_at: Time.current)
  end

  # Validate strong password
  validate :password_complexity, if: :password_required?

  private

  def password_complexity
    return if password.blank?

    errors.add :password, 'deve ter no mínimo 12 caracteres' if password.length < 12
    errors.add :password, 'deve conter pelo menos uma letra maiúscula' unless password.match?(/[A-Z]/)
    errors.add :password, 'deve conter pelo menos uma letra minúscula' unless password.match?(/[a-z]/)
    errors.add :password, 'deve conter pelo menos um número' unless password.match?(/\d/)
    errors.add :password, 'deve conter pelo menos um carácter especial (!@#$%^&*()_+-=[]{}|;:,.<>?)' unless password.match?(/[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]/)
  end

  def password_required?
    !persisted? || password.present? || password_confirmation.present?
  end

  # Set default role for new users
  def set_default_role
    self.role ||= :commercial
  end

  # Ensure new users must change password on first login
  def set_must_change_password
    self.must_change_password = true if must_change_password.nil?
  end

  # Skip email confirmation in development environment
  def skip_confirmation_in_development
    confirm if Rails.env.development? && !confirmed?
  end
end
