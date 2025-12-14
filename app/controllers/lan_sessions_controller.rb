class LanSessionsController < ApplicationController
  before_action :set_lan_session, only: [:show, :close, :destroy]

  def index
    # Pundit: Use policy_scope for index action
    @active_sessions = policy_scope(LanSession).active.includes(:lan_machine, :customer).order(:start_time)
    @recent_sessions = policy_scope(LanSession).where(status: 'fechada').includes(:lan_machine, :customer).order(end_time: :desc).limit(20)
  end

  def show
    # Pundit: Authorize show action
    authorize @lan_session
  end

  def new
    @lan_session = LanSession.new
    # Pundit: Authorize new action (checks create?)
    authorize @lan_session

    @lan_session.lan_machine_id = params[:machine_id] if params[:machine_id]
    @available_machines = LanMachine.available
    @customers = Customer.order(:name)
  end

  def create
    @lan_session = LanSession.new(lan_session_params)
    # Pundit: Authorize create action
    authorize @lan_session

    @lan_session.start_time = Time.current
    @lan_session.status = 'aberta'
    @lan_session.created_by_user = current_user

    if @lan_session.save
      redirect_to lan_machines_path, notice: 'Sessão iniciada com sucesso.'
    else
      @available_machines = LanMachine.available
      @customers = Customer.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def close
    if @lan_session.close!
      redirect_to lan_machines_path, notice: "Sessão fechada. Total: #{number_to_currency(@lan_session.total_value, unit: 'AOA', separator: '.', delimiter: ',')}"
    else
      redirect_to lan_machines_path, alert: 'Erro ao fechar sessão.'
    end
  end

  def destroy
    # Pundit: Authorize destroy action
    authorize @lan_session

    if @lan_session.destroy
      redirect_to lan_sessions_path, notice: 'Sessão removida com sucesso.'
    else
      redirect_to lan_sessions_path, alert: 'Erro ao remover sessão.'
    end
  end

  private

  def set_lan_session
    @lan_session = LanSession.find(params[:id])
  end

  def lan_session_params
    params.require(:lan_session).permit(:lan_machine_id, :customer_id, :billing_type, :package_minutes)
  end
end
