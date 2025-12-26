class PricingCalculator
  DEFAULT_PROFIT_MARGIN = 0.65 # 65% profit margin (default)
  MAX_PROFIT_MARGIN = 1.50 # 150% profit margin (maximum)
  ANGOLAN_ROUNDING = 100 # Round to nearest 100 AOA for market-friendly prices

  attr_reader :labor_cost, :material_cost, :purchase_price, :profit_margin

  def initialize(labor_cost: 0, material_cost: 0, purchase_price: 0, profit_margin: nil, tenant: nil)
    @labor_cost = labor_cost.to_f
    @material_cost = material_cost.to_f
    @purchase_price = purchase_price.to_f

    # Get tenant's configured margin or use default
    tenant_margin = tenant&.company_setting&.default_profit_margin

    # Convert percentage to decimal and validate range
    margin_decimal = if profit_margin
                       profit_margin.to_f / 100.0
                     elsif tenant_margin
                       tenant_margin.to_f / 100.0
                     else
                       DEFAULT_PROFIT_MARGIN
                     end

    @profit_margin = [[margin_decimal, 0].max, MAX_PROFIT_MARGIN].min
  end

  def total_cost
    labor_cost + material_cost + purchase_price
  end

  def suggested_price
    return 0 if total_cost.zero?

    # Calculate price with profit margin
    raw_price = total_cost * (1 + profit_margin)

    # Round to Angolan market-friendly values (nearest 100 AOA)
    rounded_price = (raw_price / ANGOLAN_ROUNDING).ceil * ANGOLAN_ROUNDING

    rounded_price
  end

  def profit_amount
    suggested_price - total_cost
  end

  def profit_percentage
    return 0 if total_cost.zero?
    ((profit_amount / total_cost) * 100).round(2)
  end

  def profit_margin_percentage
    (profit_margin * 100).round(0)
  end

  def breakdown
    {
      labor_cost: labor_cost,
      material_cost: material_cost,
      purchase_price: purchase_price,
      total_cost: total_cost,
      profit_margin: profit_margin,
      profit_margin_percentage: profit_margin_percentage,
      suggested_price: suggested_price,
      profit_amount: profit_amount,
      profit_percentage: profit_percentage
    }
  end

  # Class method for quick calculation with default 65% margin
  def self.calculate(labor_cost: 0, material_cost: 0, purchase_price: 0, profit_margin: nil)
    new(
      labor_cost: labor_cost,
      material_cost: material_cost,
      purchase_price: purchase_price,
      profit_margin: profit_margin
    ).suggested_price
  end
end
