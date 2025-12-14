class InventoryMovementsController < ApplicationController
  before_action :set_inventory_item

  def create
    @inventory_movement = @inventory_item.inventory_movements.build(inventory_movement_params)
    @inventory_movement.created_by_user = current_user

    if @inventory_movement.save
      redirect_to @inventory_item, notice: 'Movimento registado com sucesso.'
    else
      redirect_to @inventory_item, alert: "Erro: #{@inventory_movement.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    @inventory_movement = @inventory_item.inventory_movements.find(params[:id])

    if @inventory_movement.destroy
      redirect_to @inventory_item, notice: 'Movimento removido com sucesso.'
    else
      redirect_to @inventory_item, alert: 'Não foi possível remover o movimento.'
    end
  end

  private

  def set_inventory_item
    @inventory_item = InventoryItem.find(params[:inventory_item_id])
  end

  def inventory_movement_params
    params.require(:inventory_movement).permit(:movement_type, :quantity, :date, :notes)
  end
end
