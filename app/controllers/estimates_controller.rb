class EstimatesController < ApplicationController
  before_action :set_estimate, only: [:show, :edit, :update, :destroy, :submit_for_approval, :approve, :reject, :convert_to_job]
  before_action :check_manager_role, only: [:approve, :reject]

  def index
    # Pundit: Use policy_scope for index action
    @draft_estimates = policy_scope(Estimate).rascunhos.includes(:customer).recent
    @pending_estimates = policy_scope(Estimate).pendentes.includes(:customer).recent
    @approved_estimates = policy_scope(Estimate).aprovados.includes(:customer).recent.limit(10)

    # Count for notification badge
    @pending_count = @pending_estimates.count
  end

  def show
    # Pundit: Authorize show action
    authorize @estimate

    @estimate_items = @estimate.estimate_items.includes(:product)
  end

  def new
    @estimate = Estimate.new
    # Pundit: Authorize new action (checks create?)
    authorize @estimate

    @estimate.estimate_items.build
    @customers = Customer.order(:name)
    @products = Product.active.order(:name)
  end

  def create
    @estimate = Estimate.new(estimate_params)
    # Pundit: Authorize create action
    authorize @estimate

    @estimate.created_by_user = current_user
    @estimate.status = 'rascunho'

    if @estimate.save
      redirect_to @estimate, notice: 'Orçamento criado como rascunho. Envie para aprovação quando estiver pronto.'
    else
      @customers = Customer.order(:name)
      @products = Product.active.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # Pundit: Authorize edit action (checks update?)
    authorize @estimate

    @customers = Customer.order(:name)
    @products = Product.active.order(:name)
  end

  def update
    # Pundit: Authorize update action
    authorize @estimate

    if @estimate.update(estimate_params)
      redirect_to @estimate, notice: 'Orçamento atualizado com sucesso.'
    else
      @customers = Customer.order(:name)
      @products = Product.active.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # Pundit: Authorize destroy action
    authorize @estimate

    if @estimate.destroy
      redirect_to estimates_path, notice: 'Orçamento removido com sucesso.'
    else
      redirect_to estimates_path, alert: 'Não foi possível remover o orçamento.'
    end
  end

  def submit_for_approval
    if @estimate.can_submit_for_approval?
      @estimate.update(status: 'pendente_aprovacao')
      redirect_to @estimate, notice: 'Orçamento enviado para aprovação do gestor.'
    else
      redirect_to @estimate, alert: 'Não é possível enviar este orçamento para aprovação.'
    end
  end

  def approve
    if @estimate.can_approve?
      @estimate.update(status: 'aprovado', approved_by: current_user.email, approved_at: Time.current)
      redirect_to @estimate, notice: 'Orçamento aprovado com sucesso.'
    else
      redirect_to @estimate, alert: 'Este orçamento não pode ser aprovado no momento.'
    end
  end

  def reject
    if @estimate.can_approve?
      @estimate.update(status: 'recusado', approved_by: current_user.email, approved_at: Time.current)
      redirect_to @estimate, notice: 'Orçamento recusado.'
    else
      redirect_to @estimate, alert: 'Este orçamento não pode ser recusado no momento.'
    end
  end

  def convert_to_job
    begin
      job = @estimate.convert_to_job!
      redirect_to job, notice: 'Trabalho criado com sucesso a partir do orçamento.'
    rescue => e
      redirect_to @estimate, alert: "Erro ao converter: #{e.message}"
    end
  end

  private

  def set_estimate
    @estimate = Estimate.find(params[:id])
  end

  def estimate_params
    params.require(:estimate).permit(
      :customer_id, :valid_until, :notes,
      estimate_items_attributes: [:id, :product_id, :quantity, :unit_price, :subtotal, :_destroy]
    )
  end

  def check_manager_role
    unless current_user.role.in?(['admin', 'financeiro'])
      redirect_to estimates_path, alert: 'Apenas gestores podem aprovar/recusar orçamentos.'
    end
  end
end
