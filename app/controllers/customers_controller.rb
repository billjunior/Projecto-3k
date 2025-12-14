class CustomersController < ApplicationController
  before_action :set_customer, only: [:show, :edit, :update, :destroy]
  rescue_from ActiveRecord::RecordNotFound, with: :customer_not_found

  def index
    # Pundit: Use policy_scope for index action
    @customers = policy_scope(Customer)
                   .includes(:jobs, :lan_sessions, :invoices)
                   .recent
                   .page(params[:page])
                   .per(20)
  end

  def show
    # Pundit: Authorize show action
    authorize @customer

    @jobs = @customer.jobs.order(created_at: :desc).limit(10)
    @lan_sessions = @customer.lan_sessions.order(start_time: :desc).limit(10)
    @invoices = @customer.invoices.order(created_at: :desc).limit(10)
  end

  def new
    @customer = Customer.new
    # Pundit: Authorize new action (checks create?)
    authorize @customer
  end

  def create
    @customer = Customer.new(customer_params)
    # Pundit: Authorize create action
    authorize @customer

    if @customer.save
      redirect_to @customer, notice: 'Cliente criado com sucesso.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # Pundit: Authorize edit action (checks update?)
    authorize @customer
  end

  def update
    # Pundit: Authorize update action
    authorize @customer

    if @customer.update(customer_params)
      redirect_to @customer, notice: 'Cliente atualizado com sucesso.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # Pundit: Authorize destroy action
    authorize @customer

    if @customer.destroy
      redirect_to customers_path, notice: 'Cliente removido com sucesso.'
    else
      redirect_to customers_path, alert: 'Não é possível remover este cliente pois possui registros associados.'
    end
  end

  private

  def set_customer
    @customer = Customer.find(params[:id])
  end

  def customer_params
    params.require(:customer).permit(:name, :customer_type, :tax_id, :phone, :whatsapp, :email, :address, :notes)
  end

  def customer_not_found
    redirect_to customers_path, alert: 'Cliente não encontrado ou você não tem permissão para acessá-lo.'
  end
end
