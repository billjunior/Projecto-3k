class LeadsController < ApplicationController
  before_action :set_lead, only: [:show, :edit, :update, :destroy, :convert_to_customer]

  def index
    # Pundit: Use policy_scope for index action
    @leads = policy_scope(Lead).recent.page(params[:page])
    @leads = @leads.by_classification(params[:classification]) if params[:classification].present?
    @leads = @leads.not_converted if params[:status] == 'not_converted'
    @leads = @leads.converted if params[:status] == 'converted'
  end

  def show
    # Pundit: Authorize show action
    authorize @lead
  end

  def new
    @lead = Lead.new
    # Pundit: Authorize new action (checks create?)
    authorize @lead
  end

  def create
    @lead = Lead.new(lead_params)
    # Pundit: Authorize create action
    authorize @lead

    if @lead.save
      redirect_to @lead, notice: 'Lead criado com sucesso.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # Pundit: Authorize edit action (checks update?)
    authorize @lead
  end

  def update
    # Pundit: Authorize update action
    authorize @lead

    if @lead.update(lead_params)
      redirect_to @lead, notice: 'Lead atualizado com sucesso.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # Pundit: Authorize destroy action
    authorize @lead

    @lead.destroy
    redirect_to leads_path, notice: 'Lead removido com sucesso.'
  end

  def convert_to_customer
    if @lead.converted?
      redirect_to @lead, alert: 'Lead já foi convertido.'
      return
    end

    customer = @lead.convert_to_customer!
    redirect_to customer, notice: "Lead convertido em cliente com sucesso!"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to @lead, alert: "Erro ao converter lead: #{e.message}"
  end

  private

  def set_lead
    @lead = Lead.find(params[:id])
  end

  def lead_params
    params.require(:lead).permit(
      :name, :email, :phone, :company, :source, :contact_source,
      :classification, :assigned_to_user_id, :notes
    )
  end
end
