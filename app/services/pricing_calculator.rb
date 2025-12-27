class PricingCalculator
  # Precificação por Margem de Contribuição
  # Fórmula: PV = CV / (1 - MC%)
  # Onde:
  #   PV = Preço de Venda
  #   CV = Custos Variáveis
  #   MC% = Margem de Contribuição Desejada (percentual)

  DEFAULT_CONTRIBUTION_MARGIN = 0.40 # 40% margem de contribuição (padrão)
  MAX_CONTRIBUTION_MARGIN = 0.80 # 80% margem de contribuição (máximo)
  MIN_CONTRIBUTION_MARGIN = 0.10 # 10% margem de contribuição (mínimo)
  ANGOLAN_ROUNDING = 100 # Arredondar para AOA 100 mais próximo

  attr_reader :labor_cost, :material_cost, :purchase_price, :packaging_cost,
              :sales_commission_percentage, :sales_tax_percentage, :card_fee_percentage,
              :contribution_margin

  def initialize(
    labor_cost: 0,
    material_cost: 0,
    purchase_price: 0,
    packaging_cost: 0,
    sales_commission_percentage: 0,
    sales_tax_percentage: 0,
    card_fee_percentage: 0,
    contribution_margin: nil,
    tenant: nil
  )
    @labor_cost = labor_cost.to_f
    @material_cost = material_cost.to_f
    @purchase_price = purchase_price.to_f
    @packaging_cost = packaging_cost.to_f
    @sales_commission_percentage = sales_commission_percentage.to_f
    @sales_tax_percentage = sales_tax_percentage.to_f
    @card_fee_percentage = card_fee_percentage.to_f

    # Obter margem de contribuição configurada do tenant ou usar padrão
    tenant_margin = tenant&.company_setting&.default_profit_margin

    # Converter percentagem para decimal e validar intervalo
    margin_decimal = if contribution_margin
                       contribution_margin.to_f / 100.0
                     elsif tenant_margin
                       tenant_margin.to_f / 100.0
                     else
                       DEFAULT_CONTRIBUTION_MARGIN
                     end

    # Garantir que a margem está dentro dos limites
    @contribution_margin = [[margin_decimal, MIN_CONTRIBUTION_MARGIN].max, MAX_CONTRIBUTION_MARGIN].min
  end

  # Custos Variáveis Fixos (não dependem do preço de venda)
  def fixed_variable_costs
    labor_cost + material_cost + purchase_price + packaging_cost
  end

  # Custos Variáveis Percentuais (calculados sobre o preço de venda)
  def percentage_costs_rate
    (sales_commission_percentage + sales_tax_percentage + card_fee_percentage) / 100.0
  end

  # Custos Variáveis Totais (CV)
  # Para calcular, precisamos considerar que alguns custos são % do PV
  # CV = Custos Fixos + (PV × % Custos)
  # Mas como precisamos PV para calcular CV, usamos na fórmula ajustada
  def total_variable_costs(selling_price = suggested_price)
    fixed_variable_costs + (selling_price * percentage_costs_rate)
  end

  # Preço de Venda Sugerido (PV)
  # Fórmula ajustada: PV = CV_fixo / (1 - MC% - %_custos)
  def suggested_price
    return 0 if fixed_variable_costs.zero?

    # Ajustar margem de contribuição para considerar custos percentuais
    adjusted_margin = contribution_margin - percentage_costs_rate

    # Validar que a margem ajustada é positiva
    if adjusted_margin <= 0
      # Se custos percentuais são >= margem desejada, usar margem mínima
      adjusted_margin = MIN_CONTRIBUTION_MARGIN
    end

    # Calcular preço: PV = CV_fixo / (1 - MC%_ajustada)
    raw_price = fixed_variable_costs / (1 - adjusted_margin)

    # Arredondar para valores amigáveis (próximo AOA 100)
    rounded_price = (raw_price / ANGOLAN_ROUNDING).ceil * ANGOLAN_ROUNDING

    rounded_price
  end

  # Margem de Contribuição Unitária (MCu)
  # MCu = PV - CV
  def contribution_margin_amount
    suggested_price - total_variable_costs
  end

  # Percentual Real da Margem de Contribuição
  # MC% = MCu / PV × 100
  def actual_contribution_margin_percentage
    return 0 if suggested_price.zero?
    ((contribution_margin_amount / suggested_price) * 100).round(2)
  end

  # Margem Desejada (configurada)
  def target_contribution_margin_percentage
    (contribution_margin * 100).round(2)
  end

  # Breakdown completo dos custos e margens
  def breakdown
    sp = suggested_price

    {
      # Custos Variáveis Fixos
      labor_cost: labor_cost,
      material_cost: material_cost,
      purchase_price: purchase_price,
      packaging_cost: packaging_cost,
      fixed_variable_costs: fixed_variable_costs,

      # Custos Variáveis Percentuais
      sales_commission_percentage: sales_commission_percentage,
      sales_tax_percentage: sales_tax_percentage,
      card_fee_percentage: card_fee_percentage,
      percentage_costs_amount: sp * percentage_costs_rate,

      # Custos Totais
      total_variable_costs: total_variable_costs(sp),

      # Margem de Contribuição
      target_contribution_margin_percentage: target_contribution_margin_percentage,
      contribution_margin_amount: contribution_margin_amount,
      actual_contribution_margin_percentage: actual_contribution_margin_percentage,

      # Preço
      suggested_price: sp
    }
  end

  # Método para exportar como hash legível
  def to_h
    breakdown
  end

  # Classe método para cálculo rápido
  def self.calculate(
    labor_cost: 0,
    material_cost: 0,
    purchase_price: 0,
    packaging_cost: 0,
    sales_commission_percentage: 0,
    sales_tax_percentage: 0,
    card_fee_percentage: 0,
    contribution_margin: nil,
    tenant: nil
  )
    new(
      labor_cost: labor_cost,
      material_cost: material_cost,
      purchase_price: purchase_price,
      packaging_cost: packaging_cost,
      sales_commission_percentage: sales_commission_percentage,
      sales_tax_percentage: sales_tax_percentage,
      card_fee_percentage: card_fee_percentage,
      contribution_margin: contribution_margin,
      tenant: tenant
    ).suggested_price
  end
end
