class MissingItemsController < ApplicationController
  before_action :set_missing_item, only: [:show, :edit, :update, :destroy, :mark_as_ordered, :mark_as_resolved]

  def index
    # Pundit: Use policy_scope for index action
    @missing_items = policy_scope(MissingItem).includes(:inventory_item, :created_by_user).by_urgency

    # Filter by status if requested
    if params[:filter] == 'pending'
      @missing_items = @missing_items.pending
    elsif params[:filter] == 'ordered'
      @missing_items = @missing_items.ordered
    elsif params[:filter] == 'resolved'
      @missing_items = @missing_items.resolved
    end

    # Filter by urgency level if requested
    if params[:urgency].present? && MissingItem.urgency_levels.keys.include?(params[:urgency])
      @missing_items = @missing_items.where(urgency_level: params[:urgency])
    end

    # Pagination
    @missing_items = @missing_items.page(params[:page]).per(20)
  end

  def show
    # Pundit: Authorize show action
    authorize @missing_item
  end

  def new
    @missing_item = MissingItem.new
    # Pundit: Authorize new action (checks create?)
    authorize @missing_item

    # Load inventory items for dropdown (optional link)
    @inventory_items = InventoryItem.order(:product_name)
  end

  def create
    @missing_item = MissingItem.new(missing_item_params)
    @missing_item.source = :manual
    @missing_item.created_by_user = current_user
    # Pundit: Authorize create action
    authorize @missing_item

    if @missing_item.save
      redirect_to missing_items_path, notice: 'Item em falta registado com sucesso.'
    else
      @inventory_items = InventoryItem.order(:product_name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # Pundit: Authorize edit action (checks update?)
    authorize @missing_item
    @inventory_items = InventoryItem.order(:product_name)
  end

  def update
    # Pundit: Authorize update action
    authorize @missing_item

    if @missing_item.update(missing_item_params)
      redirect_to missing_item_path(@missing_item), notice: 'Item em falta atualizado com sucesso.'
    else
      @inventory_items = InventoryItem.order(:product_name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # Pundit: Authorize destroy action
    authorize @missing_item

    @missing_item.destroy
    redirect_to missing_items_path, notice: 'Item em falta removido com sucesso.'
  end

  def mark_as_ordered
    # Pundit: Authorize mark_as_ordered action
    authorize @missing_item

    if @missing_item.update(status: :ordered)
      redirect_to missing_item_path(@missing_item), notice: 'Item marcado como pedido.'
    else
      redirect_to missing_item_path(@missing_item), alert: 'Erro ao atualizar status.'
    end
  end

  def mark_as_resolved
    # Pundit: Authorize mark_as_resolved action
    authorize @missing_item

    if @missing_item.update(status: :resolved)
      redirect_to missing_items_path, notice: 'Item marcado como resolvido.'
    else
      redirect_to missing_item_path(@missing_item), alert: 'Erro ao atualizar status.'
    end
  end

  private

  def set_missing_item
    @missing_item = MissingItem.find(params[:id])
  end

  def missing_item_params
    params.require(:missing_item).permit(:item_name, :description, :urgency_level, :inventory_item_id, :status)
  end
end
