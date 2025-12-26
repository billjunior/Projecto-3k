class Opportunity < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant :tenant

  # Associations
  belongs_to :tenant
  belongs_to :customer
  belongs_to :lead, optional: true
  belongs_to :assigned_to_user, class_name: 'User', optional: true
  belongs_to :created_by_user, class_name: 'User', optional: true
  has_many :communications, as: :communicable, dependent: :destroy

  # Enums
  enum stage: {
    new_opportunity: 0,
    qualified: 1,
    proposal: 2,
    negotiation: 3,
    won: 4,
    lost: 5
  }

  enum contact_source: {
    whatsapp: 0,
    telefone: 1,
    instagram: 2,
    facebook: 3,
    twitter: 4,
    outro: 5
  }

  # Validations
  validates :title, presence: true
  validates :customer, presence: true
  validates :stage, presence: true
  validates :probability, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :value, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Scopes
  scope :open, -> { where(stage: [:new_opportunity, :qualified, :proposal, :negotiation]) }
  scope :closed, -> { where(stage: [:won, :lost]) }
  scope :by_stage, ->(stage) { where(stage: stage) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_expected_close, -> { order(expected_close_date: :asc) }

  # Instance methods
  def open?
    [:new_opportunity, :qualified, :proposal, :negotiation].include?(stage.to_sym)
  end

  def closed?
    [:won, :lost].include?(stage.to_sym)
  end

  def won?
    stage.to_sym == :won
  end

  def lost?
    stage.to_sym == :lost
  end

  def weighted_value
    return 0 if value.nil? || probability.nil?
    value * (probability / 100.0)
  end

  def mark_as_won!(reason = nil)
    update!(
      stage: :won,
      actual_close_date: Date.today,
      won_lost_reason: reason
    )
  end

  def mark_as_lost!(reason)
    update!(
      stage: :lost,
      actual_close_date: Date.today,
      won_lost_reason: reason
    )
  end

  def convert_to_estimate!(attributes = {})
    estimate = Estimate.create!({
      tenant: tenant,
      customer: customer,
      created_by_user: created_by_user || assigned_to_user,
      status: :pending,
      notes: "Convertido de oportunidade: #{title}\n\n#{description}"
    }.merge(attributes))

    mark_as_won!("Convertido em orçamento ##{estimate.id}")

    estimate
  end

  def stage_display_name
    case stage.to_sym
    when :new_opportunity then 'Novo'
    when :qualified then 'Qualificado'
    when :proposal then 'Proposta'
    when :negotiation then 'Negociação'
    when :won then 'Ganho'
    when :lost then 'Perdido'
    else stage.humanize
    end
  end

  def contact_source_display_name
    case contact_source&.to_sym
    when :whatsapp then 'WhatsApp'
    when :telefone then 'Telefone'
    when :instagram then 'Instagram'
    when :facebook then 'Facebook'
    when :twitter then 'X (Twitter)'
    when :outro then 'Outro'
    else 'Não especificado'
    end
  end

  def contact_source_icon
    case contact_source&.to_sym
    when :whatsapp then 'bi-whatsapp'
    when :telefone then 'bi-telephone'
    when :instagram then 'bi-instagram'
    when :facebook then 'bi-facebook'
    when :twitter then 'bi-twitter'
    when :outro then 'bi-question-circle'
    else 'bi-dash-circle'
    end
  end
end
