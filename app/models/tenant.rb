class Tenant < ApplicationRecord
  # Active Storage for logo
  has_one_attached :logo

  # Associations
  has_many :users, dependent: :destroy
  has_one :company_setting, dependent: :destroy

  # Enums (mantém status antigo para compatibilidade)
  enum status: { active: 0, expired: 1, suspended: 2 }

  # Validations
  validates :name, presence: true
  validates :subdomain, presence: true, uniqueness: true
  validates :status, presence: true

  # Scopes
  scope :active_subscriptions, -> { where(subscription_status: 'active') }
  scope :expired_subscriptions, -> { where(subscription_status: 'expired') }
  scope :trial_subscriptions, -> { where(subscription_status: 'trial') }
  scope :expiring_soon, -> (days = 7) {
    where('subscription_expires_at BETWEEN ? AND ?', Time.current, Time.current + days.days)
      .where(subscription_status: ['active', 'trial'])
  }

  # Subscription Instance Methods

  # Verificar se a subscrição está ativa (pago e não expirado)
  def subscription_active?
    return false if subscription_expires_at.nil?
    subscription_status == 'active' && subscription_expires_at > Time.current
  end

  # Verificar se está no período de teste
  def in_trial?
    subscription_status == 'trial' && subscription_expires_at.present? && subscription_expires_at > Time.current
  end

  # Verificar se pode acessar o sistema (trial ou active)
  def can_access?
    (subscription_active? || in_trial?) && !suspended?
  end

  # Verificar se está suspenso
  def suspended?
    subscription_status == 'suspended'
  end

  # Dias restantes até expirar
  def days_remaining
    return 0 unless subscription_expires_at
    ((subscription_expires_at - Time.current) / 1.day).to_i
  end

  # Verificar se está expirando em breve
  def expiring_soon?(days_threshold = 7)
    remaining = days_remaining
    remaining > 0 && remaining <= days_threshold
  end

  # Renovar subscrição (adicionar meses)
  def renew_subscription!(months = 1)
    # Se ainda não expirou, adiciona a partir da data atual de expiração
    # Se já expirou, adiciona a partir de agora
    new_expiration = if subscription_expires_at && subscription_expires_at > Time.current
                       subscription_expires_at + months.months
                     else
                       Time.current + months.months
                     end

    update!(
      subscription_status: 'active',
      subscription_expires_at: new_expiration,
      last_payment_date: Time.current
    )
  end

  # Expirar subscrição
  def expire_subscription!
    update!(subscription_status: 'expired')
  end

  # Suspender subscrição (bloqueio manual)
  def suspend_subscription!
    update!(subscription_status: 'suspended')
  end

  # Ativar subscrição suspensa
  def activate_subscription!
    if subscription_expires_at && subscription_expires_at > Time.current
      update!(subscription_status: 'active')
    else
      update!(subscription_status: 'expired')
    end
  end

  # Nome do plano formatado
  def plan_name
    case subscription_plan
    when 'monthly' then 'Mensal'
    when 'quarterly' then 'Trimestral'
    when 'yearly' then 'Anual'
    else subscription_plan.to_s.titleize
    end
  end

  # Badge CSS class baseado no status
  def subscription_badge_class
    case subscription_status
    when 'active' then 'bg-success'
    when 'trial' then 'bg-info'
    when 'expired' then 'bg-danger'
    when 'suspended' then 'bg-warning'
    else 'bg-secondary'
    end
  end

  # Métodos antigos mantidos para compatibilidade
  def active?
    can_access?
  end

  def expired?
    subscription_status == 'expired'
  end

  def days_until_expiration
    days_remaining
  end
end
