class PriceRulesController < ApplicationController
  before_action :set_product

  def create
    @price_rule = @product.price_rules.build(price_rule_params)

    if @price_rule.save
      redirect_to @product, notice: 'Regra de preço criada com sucesso.'
    else
      redirect_to @product, alert: "Erro ao criar regra: #{@price_rule.errors.full_messages.join(', ')}"
    end
  end

  def update
    @price_rule = @product.price_rules.find(params[:id])

    if @price_rule.update(price_rule_params)
      redirect_to @product, notice: 'Regra de preço atualizada com sucesso.'
    else
      redirect_to @product, alert: "Erro ao atualizar regra: #{@price_rule.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    @price_rule = @product.price_rules.find(params[:id])
    @price_rule.destroy
    redirect_to @product, notice: 'Regra de preço removida com sucesso.'
  end

  private

  def set_product
    @product = Product.find(params[:product_id])
  end

  def price_rule_params
    params.require(:price_rule).permit(:min_qty, :max_qty, :unit_price)
  end
end
