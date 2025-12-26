class PricingAnalyzer
  attr_reader :document, :tenant, :expected_margin

  def initialize(document)
    @document = document
    @tenant = document.tenant
    @expected_margin = tenant.company_setting&.default_profit_margin || 65.0
  end

  def analyze
    {
      expected_margin: expected_margin,
      total_cost: total_cost,
      total_revenue: total_revenue,
      total_profit: total_profit,
      actual_margin_percentage: actual_margin_percentage,
      margin_deficit: margin_deficit,
      profit_loss: profit_loss,
      below_margin_items: below_margin_items,
      has_warnings: has_warnings?,
      severity: calculate_severity
    }
  end

  private

  def items
    @items ||= if document.respond_to?(:estimate_items)
                 document.estimate_items.reject(&:marked_for_destruction?)
               else
                 document.invoice_items.reject(&:marked_for_destruction?)
               end
  end

  def total_cost
    @total_cost ||= items.sum do |item|
      product = item.product
      next 0 unless product

      unit_cost = product.labor_cost.to_f + product.material_cost.to_f + product.purchase_price.to_f
      unit_cost * item.quantity.to_f
    end
  end

  def total_revenue
    @total_revenue ||= document.total_value.to_f
  end

  def total_profit
    @total_profit ||= total_revenue - total_cost
  end

  def actual_margin_percentage
    return 0 if total_cost.zero?
    @actual_margin_percentage ||= ((total_profit / total_cost) * 100).round(2)
  end

  def margin_deficit
    @margin_deficit ||= [expected_margin - actual_margin_percentage, 0].max
  end

  def profit_loss
    return 0 if total_cost.zero?
    @profit_loss ||= begin
      expected_profit = total_cost * (expected_margin / 100.0)
      [expected_profit - total_profit, 0].max
    end
  end

  def below_margin_items
    @below_margin_items ||= items.map do |item|
      product = item.product
      next nil unless product

      unit_cost = product.labor_cost.to_f + product.material_cost.to_f + product.purchase_price.to_f
      unit_price = item.unit_price.to_f

      next nil if unit_cost.zero?

      item_margin = ((unit_price - unit_cost) / unit_cost * 100).round(2)

      if item_margin < expected_margin
        {
          item_id: item.id,
          product_id: product.id,
          product_name: product.name,
          unit_cost: unit_cost,
          unit_price: unit_price,
          quantity: item.quantity,
          margin_percentage: item_margin,
          margin_gap: expected_margin - item_margin,
          profit_loss: ((expected_margin - item_margin) / 100.0 * unit_cost * item.quantity).round(2)
        }
      end
    end.compact
  end

  def has_warnings?
    margin_deficit > 0 || below_margin_items.any?
  end

  def calculate_severity
    case margin_deficit
    when 0..5
      'low'
    when 5..15
      'medium'
    else
      'high'
    end
  end
end
