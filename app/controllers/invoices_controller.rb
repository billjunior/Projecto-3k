class InvoicesController < ApplicationController
  before_action :set_invoice, only: [:show, :edit, :update, :destroy, :pdf]

  def index
    @pending_invoices = policy_scope(Invoice).pending.includes(:customer).recent
    @paid_invoices = policy_scope(Invoice).paid.includes(:customer).recent.limit(20)
    @partial_invoices = policy_scope(Invoice).where(status: 'parcial').includes(:customer).recent
  end

  def show
    authorize @invoice
    @invoice_items = @invoice.invoice_items.includes(:product)
    @payments = @invoice.payments.order(created_at: :desc)
  end

  def new
    @invoice = Invoice.new
    authorize @invoice
    @invoice.invoice_items.build
    @invoice.invoice_date = Date.today
    @customers = Customer.order(:name)
    @products = Product.active.order(:name)
  end

  def create
    @invoice = Invoice.new(invoice_params)
    authorize @invoice
    @invoice.created_by_user = current_user
    @invoice.status = 'pendente'

    if @invoice.save
      redirect_to @invoice, notice: 'Fatura criada com sucesso.'
    else
      @customers = Customer.order(:name)
      @products = Product.active.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @invoice
    @customers = Customer.order(:name)
    @products = Product.active.order(:name)
  end

  def update
    authorize @invoice

    if @invoice.update(invoice_params)
      redirect_to @invoice, notice: 'Fatura atualizada com sucesso.'
    else
      @customers = Customer.order(:name)
      @products = Product.active.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @invoice

    if @invoice.destroy
      redirect_to invoices_path, notice: 'Fatura removida com sucesso.'
    else
      redirect_to invoices_path, alert: 'Não foi possível remover a fatura.'
    end
  end

  def pdf
    pdf = InvoicePdf.new(@invoice).generate
    send_data pdf, filename: "fatura_#{@invoice.id.to_s.rjust(6, '0')}.pdf",
                   type: 'application/pdf',
                   disposition: 'inline'
  end

  def pricing_calculator
    @products = Product.active.order(:name)
    @calculator = PricingCalculator.new
  end

  def calculate_price
    @calculator = PricingCalculator.new(
      labor_cost: params[:labor_cost],
      material_cost: params[:material_cost],
      purchase_price: params[:purchase_price],
      profit_margin: params[:profit_margin]
    )

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          'pricing_result',
          partial: 'invoices/pricing_result',
          locals: { calculator: @calculator }
        )
      end
      format.html { redirect_to pricing_calculator_invoices_path }
    end
  end

  private

  def set_invoice
    @invoice = Invoice.find(params[:id])
  end

  def invoice_params
    params.require(:invoice).permit(
      :customer_id, :invoice_type, :invoice_date, :due_date, :total_value,
      invoice_items_attributes: [:id, :product_id, :description, :quantity, :unit_price, :subtotal, :_destroy]
    )
  end
end
