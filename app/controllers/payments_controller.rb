class PaymentsController < ApplicationController
  before_action :set_invoice

  def create
    @payment = @invoice.payments.build(payment_params)
    # Pundit: Authorize create action
    authorize @payment

    @payment.payment_date = Date.today

    if @payment.save
      @invoice.reload
      redirect_to @invoice, notice: 'Pagamento registrado com sucesso.'
    else
      redirect_to @invoice, alert: "Erro: #{@payment.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    @payment = @invoice.payments.find(params[:id])
    # Pundit: Authorize destroy action
    authorize @payment

    @payment.destroy
    @invoice.reload
    redirect_to @invoice, notice: 'Pagamento removido com sucesso.'
  end

  private

  def set_invoice
    @invoice = Invoice.find(params[:invoice_id])
  end

  def payment_params
    params.require(:payment).permit(:amount, :payment_method, :notes)
  end
end
