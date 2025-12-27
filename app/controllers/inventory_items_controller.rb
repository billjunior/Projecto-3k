class InventoryItemsController < ApplicationController
  before_action :set_inventory_item, only: [:show, :edit, :update, :destroy]

  def index
    # Pundit: Use policy_scope for index action
    @inventory_items = policy_scope(InventoryItem).includes(:inventory_movements).order(:product_name)

    # Filter by stock status if requested
    if params[:filter] == 'low_stock'
      @inventory_items = @inventory_items.low_stock
    elsif params[:filter] == 'out_of_stock'
      @inventory_items = @inventory_items.out_of_stock
    elsif params[:filter] == 'in_stock'
      @inventory_items = @inventory_items.in_stock
    end

    # Filter by month if requested
    if params[:month].present? && params[:year].present?
      @selected_month = params[:month].to_i
      @selected_year = params[:year].to_i
    end

    # Pagination
    @inventory_items = @inventory_items.page(params[:page]).per(20)

    respond_to do |format|
      format.html
      format.pdf do
        all_items = policy_scope(InventoryItem).includes(:inventory_movements).order(:product_name)
        pdf = InventoryReportPdf.new(ActsAsTenant.current_tenant, all_items).generate
        send_data pdf, filename: "relatorio_inventario_#{Time.current.strftime('%Y%m%d')}.pdf",
                       type: 'application/pdf',
                       disposition: 'inline'
      end
    end
  end

  def show
    # Pundit: Authorize show action
    authorize @inventory_item

    @movements = @inventory_item.inventory_movements.order(date: :desc)

    # Group movements by month for chart/summary
    @movements_by_month = @movements.group_by { |m| m.date.beginning_of_month }
  end

  def new
    @inventory_item = InventoryItem.new
    # Pundit: Authorize new action (checks create?)
    authorize @inventory_item
  end

  def create
    @inventory_item = InventoryItem.new(inventory_item_params)
    # Pundit: Authorize create action
    authorize @inventory_item

    if @inventory_item.save
      redirect_to inventory_items_path, notice: 'Produto adicionado ao inventário com sucesso.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # Pundit: Authorize edit action (checks update?)
    authorize @inventory_item
  end

  def update
    # Pundit: Authorize update action
    authorize @inventory_item

    if @inventory_item.update(inventory_item_params)
      redirect_to @inventory_item, notice: 'Produto atualizado com sucesso.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # Pundit: Authorize destroy action
    authorize @inventory_item

    if @inventory_item.destroy
      redirect_to inventory_items_path, notice: 'Produto removido do inventário.'
    else
      redirect_to inventory_items_path, alert: 'Não é possível remover este produto pois possui movimentos associados.'
    end
  end

  def reports
    @most_purchased = InventoryItem.joins(:inventory_movements)
                                   .where(inventory_movements: { movement_type: 'entry' })
                                   .select('inventory_items.*, SUM(inventory_movements.quantity) as total_entries')
                                   .group('inventory_items.id')
                                   .order('total_entries DESC')
                                   .limit(10)

    @most_exits = InventoryItem.joins(:inventory_movements)
                               .where(inventory_movements: { movement_type: 'exit' })
                               .select('inventory_items.*, SUM(inventory_movements.quantity) as total_exits')
                               .group('inventory_items.id')
                               .order('total_exits DESC')
                               .limit(10)

    # Filter by month if requested
    if params[:month].present? && params[:year].present?
      month = params[:month].to_i
      year = params[:year].to_i

      @most_purchased = @most_purchased.merge(InventoryMovement.by_month(month, year))
      @most_exits = @most_exits.merge(InventoryMovement.by_month(month, year))

      @selected_month = month
      @selected_year = year
    end

    respond_to do |format|
      format.html
      format.pdf do
        pdf = InventoryAnalysisReportPdf.new(
          ActsAsTenant.current_tenant,
          @most_purchased,
          @most_exits,
          @selected_month,
          @selected_year
        ).generate

        filename = if @selected_month && @selected_year
          "analise_inventario_#{@selected_month}_#{@selected_year}_#{Time.current.strftime('%Y%m%d')}.pdf"
        else
          "analise_inventario_#{Time.current.strftime('%Y%m%d')}.pdf"
        end

        send_data pdf,
                  filename: filename,
                  type: 'application/pdf',
                  disposition: 'inline'
      end
    end
  end

  def batch_exit
    # Process multiple inventory exits at once
    items_data = params[:items]
    general_notes = params[:notes]

    if items_data.blank?
      redirect_to inventory_items_path, alert: 'Nenhum item selecionado.'
      return
    end

    success_count = 0
    error_messages = []

    ActiveRecord::Base.transaction do
      items_data.each do |_index, item_params|
        inventory_item = InventoryItem.find_by(id: item_params[:id])

        unless inventory_item
          error_messages << "Item ID #{item_params[:id]} não encontrado"
          next
        end

        # Authorize the action
        authorize inventory_item, :update?

        quantity = item_params[:quantity].to_f

        # Create exit movement with automatic date (today)
        movement = inventory_item.inventory_movements.build(
          movement_type: :exit,
          quantity: quantity,
          date: Date.today,
          notes: general_notes.present? ? general_notes : "Saída em lote",
          created_by_user: current_user
        )

        if movement.save
          success_count += 1
        else
          error_messages << "#{inventory_item.product_name}: #{movement.errors.full_messages.join(', ')}"
          raise ActiveRecord::Rollback
        end
      end
    end

    if error_messages.any?
      redirect_to inventory_items_path, alert: "Erros: #{error_messages.join('; ')}"
    else
      redirect_to inventory_items_path, notice: "#{success_count} saída(s) processada(s) com sucesso. Data registada: #{Date.today.strftime('%d/%m/%Y')}."
    end
  end

  private

  def set_inventory_item
    @inventory_item = InventoryItem.find(params[:id])
  end

  def inventory_item_params
    params.require(:inventory_item).permit(
      :product_name,
      :supplier_phone,
      :gross_quantity,
      :net_quantity,
      :purchase_price,
      :minimum_stock,
      :notes
    )
  end
end
