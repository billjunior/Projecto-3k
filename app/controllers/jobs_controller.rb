class JobsController < ApplicationController
  before_action :set_job, only: [:show, :edit, :update, :destroy, :update_status]

  def index
    # Pundit: Use policy_scope for index action
    @status_filter = params[:status] || 'all'

    @jobs = policy_scope(Job).includes(:customer)
    @jobs = @jobs.where(status: @status_filter) unless @status_filter == 'all'
    @jobs = @jobs.recent.page(params[:page]).per(20)

    @status_counts = {
      all: policy_scope(Job).count,
      novo: policy_scope(Job).where(status: 'novo').count,
      em_design: policy_scope(Job).where(status: 'em_design').count,
      em_impressao: policy_scope(Job).where(status: 'em_impressao').count,
      em_acabamento: policy_scope(Job).where(status: 'em_acabamento').count,
      pronto: policy_scope(Job).where(status: 'pronto').count,
      entregue: policy_scope(Job).where(status: 'entregue').count
    }
  end

  def show
    # Pundit: Authorize show action
    authorize @job

    @job_items = @job.job_items.includes(:product)
    @job_files = @job.job_files
  end

  def new
    @job = Job.new
    # Pundit: Authorize new action (checks create?)
    authorize @job

    @job.job_items.build
    @customers = Customer.order(:name)
    @products = Product.active.grafica.order(:name)
  end

  def create
    @job = Job.new(job_params)
    # Pundit: Authorize create action
    authorize @job

    @job.created_by_user = current_user
    @job.status = 'novo'

    if @job.save
      redirect_to @job, notice: 'Trabalho criado com sucesso.'
    else
      @customers = Customer.order(:name)
      @products = Product.active.grafica.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # Pundit: Authorize edit action (checks update?)
    authorize @job

    @customers = Customer.order(:name)
    @products = Product.active.grafica.order(:name)
  end

  def update
    # Pundit: Authorize update action
    authorize @job

    if @job.update(job_params)
      redirect_to @job, notice: 'Trabalho atualizado com sucesso.'
    else
      @customers = Customer.order(:name)
      @products = Product.active.grafica.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # Pundit: Authorize destroy action
    authorize @job

    if @job.destroy
      redirect_to jobs_path, notice: 'Trabalho removido com sucesso.'
    else
      redirect_to jobs_path, alert: 'Não foi possível remover o trabalho.'
    end
  end

  def update_status
    if @job.update(status: params[:new_status])
      redirect_to @job, notice: 'Status atualizado com sucesso.'
    else
      redirect_to @job, alert: 'Erro ao atualizar status.'
    end
  end

  private

  def set_job
    @job = Job.find(params[:id])
  end

  def job_params
    params.require(:job).permit(
      :customer_id, :title, :description, :priority, :status,
      :delivery_date, :total_value, :advance_paid,
      job_items_attributes: [:id, :product_id, :quantity, :unit_price, :subtotal, :_destroy]
    )
  end
end
