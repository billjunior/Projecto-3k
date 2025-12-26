class EstimatesController < ApplicationController
  before_action :set_estimate, only: [:show, :edit, :update, :destroy, :submit_for_approval, :approve, :reject, :convert_to_job, :pdf]
  before_action :check_manager_role, only: [:approve, :reject]

  def index
    # Pundit: Use policy_scope for index action
    @draft_estimates = policy_scope(Estimate).rascunhos.includes(:customer).recent.page(params[:draft_page]).per(10)
    @pending_estimates = policy_scope(Estimate).pendentes.includes(:customer).recent.page(params[:pending_page]).per(10)
    @approved_estimates = policy_scope(Estimate).aprovados.includes(:customer).recent.page(params[:approved_page]).per(10)

    # Count for notification badge
    @pending_count = policy_scope(Estimate).pendentes.count
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
      PricingNotifier.new(@estimate, user: current_user).notify_if_needed
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
      PricingNotifier.new(@estimate, user: current_user).notify_if_needed
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
    authorize @estimate
    if @estimate.can_submit_for_approval?
      @estimate.update(status: 'pendente_aprovacao')

      # Send emails to managers
      company_settings = @estimate.tenant.company_setting
      managers = company_settings.missing_items_recipients  # Returns [director_general_email, financial_director_email]

      managers.each do |email|
        EstimateMailer.estimate_for_approval(@estimate, email).deliver_later
      end

      redirect_to @estimate, notice: 'Orçamento enviado para aprovação. Gestores notificados por email.'
    else
      redirect_to @estimate, alert: 'Não é possível enviar este orçamento para aprovação.'
    end
  end

  def approve
    authorize @estimate
    if @estimate.can_approve?
      @estimate.update(status: 'aprovado', approved_by: current_user.email, approved_at: Time.current)

      # Send email to customer
      if @estimate.customer.email.present?
        EstimateMailer.estimate_approved(@estimate).deliver_later
      end

      redirect_to @estimate, notice: 'Orçamento aprovado com sucesso. Email enviado ao cliente.'
    else
      redirect_to @estimate, alert: 'Este orçamento não pode ser aprovado no momento.'
    end
  end

  def reject
    authorize @estimate
    if @estimate.can_approve?
      @estimate.update(status: 'recusado', approved_by: current_user.email, approved_at: Time.current)
      redirect_to @estimate, notice: 'Orçamento recusado.'
    else
      redirect_to @estimate, alert: 'Este orçamento não pode ser recusado no momento.'
    end
  end

  def convert_to_job
    authorize @estimate
    begin
      job = @estimate.convert_to_job!
      redirect_to job, notice: 'Trabalho criado com sucesso a partir do orçamento.'
    rescue => e
      redirect_to @estimate, alert: "Erro ao converter: #{e.message}"
    end
  end

  def pdf
    authorize @estimate

    pdf = EstimatePdf.new(@estimate).generate
    send_data pdf,
              filename: "orcamento_#{@estimate.estimate_number}.pdf",
              type: 'application/pdf',
              disposition: 'inline'
  end

  def validate_pricing
    @estimate = Estimate.new(estimate_params)
    @estimate.created_by_user = current_user
    authorize @estimate

    analyzer = PricingAnalyzer.new(@estimate)
    analysis = analyzer.analyze

    render json: {
      valid: !analysis[:has_warnings],
      analysis: analysis.slice(:expected_margin, :actual_margin_percentage, :margin_deficit, :below_margin_items, :severity)
    }
  end

  private

  def set_estimate
    @estimate = Estimate.find(params[:id])
  end

  def estimate_params
    params.require(:estimate).permit(
      :customer_id, :valid_until, :notes,
      :discount_percentage, :discount_justification,
      estimate_items_attributes: [:id, :product_id, :quantity, :unit_price, :subtotal, :_destroy]
    )
  end

  def check_manager_role
    unless current_user.role.in?(['admin', 'financeiro'])
      redirect_to estimates_path, alert: 'Apenas gestores podem aprovar/recusar orçamentos.'
    end
  end
end
