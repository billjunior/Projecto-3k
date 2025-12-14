class LanMachinesController < ApplicationController
  before_action :set_lan_machine, only: [:show, :edit, :update, :destroy]

  def index
    # Pundit: Use policy_scope for index action
    @lan_machines = policy_scope(LanMachine).includes(:lan_sessions).order(:name)
    @available_machines = @lan_machines.available
    @occupied_machines = @lan_machines.occupied
  end

  def show
    # Pundit: Authorize show action
    authorize @lan_machine

    @current_session = @lan_machine.current_session
    @recent_sessions = @lan_machine.lan_sessions.order(start_time: :desc).limit(10)
  end

  def new
    @lan_machine = LanMachine.new
    # Pundit: Authorize new action (checks create?)
    authorize @lan_machine
  end

  def create
    @lan_machine = LanMachine.new(lan_machine_params)
    # Pundit: Authorize create action
    authorize @lan_machine

    if @lan_machine.save
      redirect_to lan_machines_path, notice: 'Máquina criada com sucesso.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # Pundit: Authorize edit action (checks update?)
    authorize @lan_machine
  end

  def update
    # Pundit: Authorize update action
    authorize @lan_machine

    if @lan_machine.update(lan_machine_params)
      redirect_to @lan_machine, notice: 'Máquina atualizada com sucesso.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # Pundit: Authorize destroy action
    authorize @lan_machine

    if @lan_machine.destroy
      redirect_to lan_machines_path, notice: 'Máquina removida com sucesso.'
    else
      redirect_to lan_machines_path, alert: 'Não é possível remover esta máquina pois possui sessões associadas.'
    end
  end

  private

  def set_lan_machine
    @lan_machine = LanMachine.find(params[:id])
  end

  def lan_machine_params
    params.require(:lan_machine).permit(:name, :status, :hourly_rate, :notes)
  end
end
