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
      labor_cost: labor_cost || 0,
      material_cost: material_cost || 0,
      purchase_price: purchase_price || 0,
      packaging_cost: packaging_cost || 0,
      sales_commission_percentage: sales_commission_percentage || 0,
      sales_tax_percentage: sales_tax_percentage || 0,
      card_fee_percentage: card_fee_percentage || 0,
      tenant: tenant
    )
  end

  def pricing_breakdown
    PricingCalculator.new(
      labor_cost: labor_cost || 0,
      material_cost: material_cost || 0,
      purchase_price: purchase_price || 0,
      packaging_cost: packaging_cost || 0,
      sales_commission_percentage: sales_commission_percentage || 0,
      sales_tax_percentage: sales_tax_percentage || 0,
      card_fee_percentage: card_fee_percentage || 0,
      tenant: tenant
    ).breakdown
  end

  def has_cost_data?
    (labor_cost && labor_cost.positive?) ||
    (material_cost && material_cost.positive?) ||
    (purchase_price && purchase_price.positive?) ||
    (packaging_cost && packaging_cost.positive?)
  end

  # Custo Variável Total (sem percentuais)
  def total_variable_cost
    (labor_cost || 0) + (material_cost || 0) + (purchase_price || 0) + (packaging_cost || 0)
  end

  # Percentual total de custos variáveis percentuais
  def total_percentage_costs
    (sales_commission_percentage || 0) + (sales_tax_percentage || 0) + (card_fee_percentage || 0)
  end
end
