class OpportunitiesController < ApplicationController
  before_action :set_opportunity, only: [:show, :edit, :update, :destroy, :mark_as_won, :mark_as_lost, :convert_to_estimate, :update_stage]

  def index
    # Pundit: Use policy_scope for index action
    @opportunities = policy_scope(Opportunity).includes(:customer).recent.page(params[:page])
    @opportunities = @opportunities.by_stage(params[:stage]) if params[:stage].present?
    @opportunities = @opportunities.open if params[:status] == 'open'
    @opportunities = @opportunities.closed if params[:status] == 'closed'

    # Stats para dashboard
    @stats = {
      total: policy_scope(Opportunity).count,
      open: policy_scope(Opportunity).open.count,
      won: policy_scope(Opportunity).won.count,
      lost: policy_scope(Opportunity).lost.count,
      total_value: policy_scope(Opportunity).open.sum(:value) || 0,
      weighted_value: policy_scope(Opportunity).open.sum('value * probability / 100.0') || 0
    }
  end

  def kanban
    # Pundit: Use policy_scope for kanban action
    @opportunities = policy_scope(Opportunity).includes(:customer, :assigned_to_user).all

    # Group opportunities by stage
    @opportunities_by_stage = {
      new_opportunity: [],
      qualified: [],
      proposal: [],
      negotiation: [],
      won: [],
      lost: []
    }

    @opportunities.each do |opp|
      @opportunities_by_stage[opp.stage.to_sym] << opp
    end

    # Calculate total value per stage
    @stage_values = {}
    @opportunities_by_stage.each do |stage, opps|
      @stage_values[stage] = opps.sum { |o| o.value || 0 }
    end

    # Stats para dashboard
    @stats = {
      total: policy_scope(Opportunity).count,
      open: policy_scope(Opportunity).open.count,
      won: policy_scope(Opportunity).won.count,
      lost: policy_scope(Opportunity).lost.count,
      total_value: policy_scope(Opportunity).open.sum(:value) || 0,
      weighted_value: policy_scope(Opportunity).open.sum('value * probability / 100.0') || 0
    }
  end

  def show
    # Pundit: Authorize show action
    authorize @opportunity
  end

  def new
    @opportunity = Opportunity.new
    # Pundit: Authorize new action (checks create?)
    authorize @opportunity

    @opportunity.customer_id = params[:customer_id] if params[:customer_id].present?
    @opportunity.lead_id = params[:lead_id] if params[:lead_id].present?
    @opportunity.created_by_user = current_user
  end

  def create
    @opportunity = Opportunity.new(opportunity_params)
    # Pundit: Authorize create action
    authorize @opportunity

    @opportunity.created_by_user = current_user

    if @opportunity.save
      redirect_to @opportunity, notice: 'Oportunidade criada com sucesso.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # Pundit: Authorize edit action (checks update?)
    authorize @opportunity
  end

  def update
    # Pundit: Authorize update action
    authorize @opportunity

    if @opportunity.update(opportunity_params)
      redirect_to @opportunity, notice: 'Oportunidade atualizada com sucesso.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # Pundit: Authorize destroy action
    authorize @opportunity

    @opportunity.destroy
    redirect_to opportunities_path, notice: 'Oportunidade removida com sucesso.'
  end

  def mark_as_won
    @opportunity.mark_as_won!(params[:reason])
    redirect_to @opportunity, notice: 'Oportunidade marcada como ganha!'
  end

  def mark_as_lost
    if params[:reason].blank?
      redirect_to @opportunity, alert: 'Por favor, forneça um motivo para marcar como perdida.'
      return
    end

    @opportunity.mark_as_lost!(params[:reason])
    redirect_to @opportunity, notice: 'Oportunidade marcada como perdida.'
  end

  def convert_to_estimate
    if @opportunity.closed?
      redirect_to @opportunity, alert: 'Oportunidade já está fechada.'
      return
    end

    estimate = @opportunity.convert_to_estimate!
    redirect_to estimate, notice: "Oportunidade convertida em orçamento ##{estimate.id}!"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to @opportunity, alert: "Erro ao converter: #{e.message}"
  end

  def update_stage
    new_stage = params[:stage]

    if Opportunity.stages.keys.include?(new_stage)
      @opportunity.update!(stage: new_stage)
      render json: { success: true, stage: @opportunity.stage }
    else
      render json: { success: false, error: 'Invalid stage' }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  private

  def set_opportunity
    @opportunity = Opportunity.find(params[:id])
  end

  def opportunity_params
    params.require(:opportunity).permit(
      :customer_id, :lead_id, :title, :description, :value,
      :probability, :stage, :expected_close_date, :assigned_to_user_id, :contact_source
    )
  end
end
