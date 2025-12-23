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
end
