class Estimate < ApplicationRecord
  acts_as_tenant :tenant
  # Associations
  belongs_to :customer
  belongs_to :created_by_user, class_name: 'User', foreign_key: 'created_by_user_id', optional: true
  has_many :estimate_items, dependent: :destroy
  has_many :jobs, foreign_key: 'source_estimate_id', dependent: :nullify
  has_many :pricing_warnings, as: :warnable, dependent: :destroy

  # Nested attributes
  accepts_nested_attributes_for :estimate_items, allow_destroy: true, reject_if: :all_blank

  # Validations
  validates :estimate_number, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: %w[rascunho pendente_aprovacao aprovado recusado expirado] }
  validates :total_value, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :discount_justification, presence: true, length: { minimum: 10 },
            if: :discount_applied?

  # Callbacks
  before_validation :generate_estimate_number, on: :create
  before_validation :calculate_totals_with_discount

  # Scopes
  scope :rascunhos, -> { where(status: 'rascunho') }
  scope :pendentes, -> { where(status: 'pendente_aprovacao') }
  scope :aprovados, -> { where(status: 'aprovado') }
  scope :recent, -> { order(created_at: :desc) }

  # Status helpers
  def can_submit_for_approval?
    status == 'rascunho' && estimate_items.any?
  end

  def can_approve?
    status == 'pendente_aprovacao'
  end

  def discount_applied?
    discount_percentage.present? && discount_percentage > 0
  end

  def pricing_analysis
    @pricing_analysis ||= PricingAnalyzer.new(self).analyze
  end

  def convert_to_job!
    raise 'Orçamento não aprovado' unless status == 'aprovado'

    job = Job.create!(
      customer: customer,
      source_estimate: self,
      title: "Trabalho ##{estimate_number}",
      total_value: total_value,
      created_by_user: created_by_user,
      job_number: Job.generate_job_number
    )

    estimate_items.each do |item|
      job.job_items.create!(
        product: item.product,
        quantity: item.quantity,
        unit_price: item.unit_price,
        subtotal: item.subtotal
      )
    end

    job
  end

  private

  def generate_estimate_number
    self.estimate_number ||= "ORC-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(3).upcase}"
  end

  def calculate_totals_with_discount
    # Calcula o total a partir dos items (incluindo nested attributes não salvos)
    items = estimate_items.reject(&:marked_for_destruction?)
    self.subtotal_before_discount = items.sum { |item|
      (item.quantity.to_f || 0) * (item.unit_price.to_f || 0)
    }

    if discount_percentage.present? && discount_percentage > 0
      self.discount_amount = (subtotal_before_discount * discount_percentage / 100.0).round(2)
    else
      self.discount_amount = 0.0
    end

    self.total_value = subtotal_before_discount - discount_amount
  end
end
