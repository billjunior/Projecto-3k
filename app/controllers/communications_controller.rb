class CommunicationsController < ApplicationController
  before_action :set_communicable
  before_action :set_communication, only: [:show, :edit, :update, :destroy, :mark_as_completed]

  def index
    @communications = policy_scope(Communication).where(communicable: @communicable).recent.page(params[:page])
    @communications = @communications.by_type(params[:type]) if params[:type].present?
    authorize Communication
  end

  def show
    authorize @communication
  end

  def new
    @communication = @communicable.communications.build
    @communication.created_by_user = current_user
    authorize @communication
  end

  def create
    @communication = @communicable.communications.build(communication_params)
    @communication.created_by_user = current_user
    authorize @communication

    if @communication.save
      redirect_to_communicable, notice: 'Comunicação registada com sucesso.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @communication
  end

  def update
    authorize @communication

    if @communication.update(communication_params)
      redirect_to_communicable, notice: 'Comunicação atualizada com sucesso.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @communication

    @communication.destroy
    redirect_to_communicable, notice: 'Comunicação removida com sucesso.'
  end

  def mark_as_completed
    authorize @communication, :mark_as_completed?

    @communication.mark_as_completed!
    redirect_to_communicable, notice: 'Comunicação marcada como concluída.'
  end

  private

  def set_communicable
    if params[:customer_id]
      @communicable = Customer.find(params[:customer_id])
    elsif params[:lead_id]
      @communicable = Lead.find(params[:lead_id])
    elsif params[:opportunity_id]
      @communicable = Opportunity.find(params[:opportunity_id])
    elsif params[:contact_id]
      @communicable = Contact.find(params[:contact_id])
    else
      redirect_to root_path, alert: 'Recurso não encontrado.'
    end
  end

  def set_communication
    @communication = @communicable.communications.find(params[:id])
  end

  def communication_params
    params.require(:communication).permit(
      :communication_type, :subject, :content, :completed_at
    )
  end

  def redirect_to_communicable
    case @communicable
    when Customer
      redirect_to customer_path(@communicable)
    when Lead
      redirect_to lead_path(@communicable)
    when Opportunity
      redirect_to opportunity_path(@communicable)
    when Contact
      # Redirect to the contact's contactable
      redirect_to polymorphic_path(@communicable.contactable)
    else
      redirect_to root_path
    end
  end
end
