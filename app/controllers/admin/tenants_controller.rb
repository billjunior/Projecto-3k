class Admin::TenantsController < Admin::BaseController
  before_action :set_tenant, only: [:show, :edit, :update, :destroy, :extend_subscription]

  def index
    @tenants = Tenant.all.order(created_at: :desc)
  end

  def show
  end

  def new
    @tenant = Tenant.new
  end

  def create
    @tenant = Tenant.new(tenant_params)
    if @tenant.save
      redirect_to admin_tenant_path(@tenant), notice: 'Tenant criado com sucesso.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @tenant.update(tenant_params)
      redirect_to admin_tenant_path(@tenant), notice: 'Tenant atualizado com sucesso.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @tenant.destroy
    redirect_to admin_tenants_path, notice: 'Tenant removido com sucesso.'
  end

  def extend_subscription
    months = params[:months].to_i
    if months > 0
      new_end_date = @tenant.subscription_end ? @tenant.subscription_end + months.months : Date.today + months.months
      @tenant.update(subscription_end: new_end_date, status: :active)
      redirect_to admin_tenant_path(@tenant), notice: "Subscrição estendida por #{months} meses."
    else
      redirect_to admin_tenant_path(@tenant), alert: 'Número de meses inválido.'
    end
  end

  private

  def set_tenant
    @tenant = Tenant.find(params[:id])
  end

  def tenant_params
    params.require(:tenant).permit(:name, :subdomain, :status, :subscription_start, :subscription_end, :logo, settings: {})
  end
end
