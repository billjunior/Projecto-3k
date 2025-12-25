class ApplicationController < ActionController::Base
  # Pundit Authorization
  include Pundit::Authorization

  before_action :authenticate_user!
  before_action :set_current_user
  before_action :set_current_tenant
  before_action :check_tenant_subscription
  before_action :check_crm_access
  before_action :configure_permitted_parameters, if: :devise_controller?

  # Pundit: Handle unauthorized access
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Use devise layout for authentication pages
  layout :determine_layout

  protected

  def set_current_user
    if current_user
      Current.user = current_user
      Current.ip_address = request.remote_ip
      Current.user_agent = request.user_agent
    end
  end

  def set_current_tenant
    if current_user
      ActsAsTenant.current_tenant = current_user.tenant
    end
  end

  def check_tenant_subscription
    return if devise_controller? # Não verificar em login/logout
    return unless current_user
    return if current_user.super_admin? # Super admins não são bloqueados
    return if controller_name == 'subscriptions' # Permitir acesso à página de expiração
    return if controller_path == 'admin/subscriptions' # Permitir admin gerenciar subscrições

    tenant = current_user.tenant

    if tenant && !tenant.can_access?
      redirect_to expired_subscription_path, alert: 'Sua subscrição expirou ou foi suspensa. Renove para continuar usando o sistema.'
    elsif tenant && tenant.expiring_soon?(7)
      flash.now[:warning] = "Sua subscrição expira em #{tenant.days_remaining} dias. Renove agora para evitar interrupções!"
    end
  end

  def check_crm_access
    return if devise_controller?
    return unless current_user
    # Skip check for Cyber Café controllers
    return if ['lan_machines', 'lan_sessions', 'daily_revenues', 'training_courses', 'inventory_items', 'inventory_movements'].include?(controller_name)

    # Cyber tech users should NOT access CRM main system
    if current_user.cyber_tech? && !current_user.super_admin?
      redirect_to lan_machines_path, alert: 'Você não tem acesso ao sistema CRM principal. Acesse o Cyber Café.'
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :role])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  # Pundit: Return current_user for authorization
  def pundit_user
    current_user
  end

  private

  def determine_layout
    devise_controller? ? 'devise' : 'application'
  end

  def user_not_authorized
    flash[:alert] = "Você não tem permissão para executar esta ação."
    redirect_to(request.referrer || root_path)
  end
end
