class Customer < ApplicationRecord
  acts_as_tenant :tenant
  # Associations
  has_many :estimates, dependent: :restrict_with_error
  has_many :jobs, dependent: :restrict_with_error
  has_many :lan_sessions, dependent: :restrict_with_error
  has_many :invoices, dependent: :restrict_with_error

  # Validations
  validates :name, presence: true
  validates :customer_type, presence: true, inclusion: { in: %w[particular empresa escola governo ong revendedor parceiro fornecedor franquia startup] }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :phone, presence: true

  # Scopes
  scope :particulares, -> { where(customer_type: 'particular') }
  scope :empresas, -> { where(customer_type: 'empresa') }
  scope :escolas, -> { where(customer_type: 'escola') }
  scope :governos, -> { where(customer_type: 'governo') }
  scope :ongs, -> { where(customer_type: 'ong') }
  scope :revendedores, -> { where(customer_type: 'revendedor') }
  scope :parceiros, -> { where(customer_type: 'parceiro') }
  scope :fornecedores, -> { where(customer_type: 'fornecedor') }
  scope :franquias, -> { where(customer_type: 'franquia') }
  scope :startups, -> { where(customer_type: 'startup') }
  scope :recent, -> { order(created_at: :desc) }

  def display_name
    if %w[empresa escola governo ong revendedor fornecedor franquia startup].include?(customer_type) && tax_id.present?
      "#{name} (NIF: #{tax_id})"
    else
      name
    end
  end

  def customer_type_label
    case customer_type
    when 'particular' then 'Particular'
    when 'empresa' then 'Empresa'
    when 'escola' then 'Escola'
    when 'governo' then 'Governo'
    when 'ong' then 'ONG'
    when 'revendedor' then 'Revendedor'
    when 'parceiro' then 'Parceiro'
    when 'fornecedor' then 'Fornecedor'
    when 'franquia' then 'Franquia'
    when 'startup' then 'Startup'
    else customer_type&.capitalize
    end
  end
end
