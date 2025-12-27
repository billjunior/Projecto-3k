class ProductsController < ApplicationController
  before_action :set_product, only: [:show, :edit, :update, :destroy]

  def index
    @products = policy_scope(Product).includes(:price_rules).order(:name).page(params[:page]).per(20)
  end

  def show
    authorize @product
    @price_rules = @product.price_rules.order(:min_qty)
  end

  def new
    @product = Product.new
    authorize @product
  end

  def create
    @product = Product.new(product_params)
    authorize @product

    if @product.save
      redirect_to @product, notice: 'Produto criado com sucesso.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @product
  end

  def update
    authorize @product

    if @product.update(product_params)
      redirect_to @product, notice: 'Produto atualizado com sucesso.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @product

    if @product.destroy
      redirect_to products_path, notice: 'Produto removido com sucesso.'
    else
      redirect_to products_path, alert: 'Não é possível remover este produto pois está em uso.'
    end
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def product_params
    params.require(:product).permit(
      :name, :category, :unit, :base_price, :active,
      :labor_cost, :material_cost, :purchase_price, :packaging_cost,
      :sales_commission_percentage, :sales_tax_percentage, :card_fee_percentage
    )
  end
end
