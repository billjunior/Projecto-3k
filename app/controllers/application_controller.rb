class ApplicationController < ActionController::Base
  # Pundit Authorization
  include Pundit::Authorization

  before_action :authenticate_user!
  before_action :set_current_tenant
  before_action :check_subscription_status
  before_action :check_crm_access
  before_action :configure_permitted_parameters, if: :devise_controller?

  # Pundit: Handle unauthorized access
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Use devise layout for authentication pages
  layout :determine_layout

  protected

  def set_current_tenant
    if current_user
      ActsAsTenant.current_tenant = current_user.tenant
    end
  end

  def check_subscription_status
    return if devise_controller? # Não verificar em login/logout
    return unless current_user
    return if current_user.super_admin? # Super admins não são bloqueados
    return if controller_name == 'subscriptions' # Permitir acesso à página de expiração

    if current_user.tenant && current_user.tenant.expired?
      redirect_to subscription_expired_path, alert: 'Subscrição expirada'
    end
  end

  def check_crm_access
    return if devise_controller?
    return unless current_user
    return if controller_path.start_with?('cyber/') # Skip for Cyber namespace

    # Cyber tech users should NOT access CRM main system
    if current_user.cyber_tech? && !current_user.super_admin?
      redirect_to cyber_dashboard_path, alert: 'Você não tem acesso ao sistema CRM principal. Acesse o Cyber Café.'
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
