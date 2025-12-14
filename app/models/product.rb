class Product < ApplicationRecord
  acts_as_tenant :tenant
  # Associations
  has_many :price_rules, dependent: :destroy
  has_many :estimate_items, dependent: :restrict_with_error
  has_many :job_items, dependent: :restrict_with_error

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :category, presence: true, inclusion: { in: %w[grafica lanhouse ambos] }
  validates :unit, presence: true
  validates :base_price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :grafica, -> { where(category: ['grafica', 'ambos']) }
  scope :lanhouse, -> { where(category: ['lanhouse', 'ambos']) }

  def price_for_quantity(qty)
    rule = price_rules.where('min_qty <= ? AND (max_qty IS NULL OR max_qty >= ?)', qty, qty).order(min_qty: :desc).first
    rule ? rule.unit_price : base_price
  end

  def suggested_price
    PricingCalculator.calculate(
      labor_cost: labor_cost,
      material_cost: material_cost,
      purchase_price: purchase_price
    )
  end

  def pricing_breakdown
    PricingCalculator.new(
      labor_cost: labor_cost,
      material_cost: material_cost,
      purchase_price: purchase_price
    ).breakdown
  end

  def has_cost_data?
    labor_cost.positive? || material_cost.positive? || purchase_price.positive?
  end
end
