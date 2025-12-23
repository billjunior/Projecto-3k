class ServicesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_service, only: [:edit, :update, :destroy, :toggle_active]
  before_action :check_edit_access, only: [:new, :create, :edit, :update, :destroy, :toggle_active]

  def index
    @services = Service.ordered.page(params[:page]).per(20)
    @services_by_category = Service.grouped_by_category
  end

  def new
    @service = Service.new
  end

  def create
    @service = Service.new(service_params)
    if @service.save
      redirect_to services_path, notice: 'Serviço criado com sucesso.'
    else
      flash.now[:alert] = "Erro ao criar serviço: #{@service.errors.full_messages.join(', ')}"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @service.update(service_params)
      redirect_to services_path, notice: 'Serviço atualizado com sucesso.'
    else
      flash.now[:alert] = "Erro ao atualizar serviço: #{@service.errors.full_messages.join(', ')}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @service.destroy
    redirect_to services_path, notice: 'Serviço removido com sucesso.'
  end

  def toggle_active
    @service.update(active: !@service.active)
    redirect_to services_path, notice: "Serviço #{@service.active? ? 'ativado' : 'desativado'} com sucesso."
  end

  private

  def set_service
    @service = Service.find(params[:id])
  end

  def check_edit_access
    unless current_user.admin? || current_user.super_admin?
      redirect_to services_path, alert: 'Acesso negado. Apenas administradores podem editar serviços.'
    end
  end

  def service_params
    params.require(:service).permit(:category, :name, :description, :estimated_time, :availability, :active)
  end
end
