# frozen_string_literal: true

# Securable concern - Security methods for controllers
module Securable
  extend ActiveSupport::Concern

  included do
    # Verify authorization after each action (Pundit)
    # Disable for index actions as they use policy_scope instead
    after_action :verify_authorized, except: [:index], unless: :devise_controller?
    after_action :verify_policy_scoped, only: [:index], unless: :devise_controller?
  end

  # Check if user can access Cyber Cafe module
  def ensure_cyber_access!
    unless current_user.can_access_cyber?
      flash[:alert] = "Você não tem permissão para acessar o Cyber Café."
      redirect_to root_path
    end
  end

  # Check if user can access CRM module
  def ensure_crm_access!
    unless current_user.can_access_crm?
      flash[:alert] = "Você não tem permissão para acessar o CRM."
      redirect_to cyber_dashboard_path
    end
  end

  # Check if user is admin or super_admin
  def ensure_admin!
    unless current_user.admin? || current_user.super_admin?
      flash[:alert] = "Apenas administradores podem acessar esta página."
      redirect_to root_path
    end
  end

  # Check if user is super_admin
  def ensure_super_admin!
    unless current_user.super_admin?
      flash[:alert] = "Apenas o super administrador pode acessar esta página."
      redirect_to root_path
    end
  end

  # Log security event
  def log_security_event(event_type, details = {})
    Rails.logger.warn "[SECURITY] #{event_type}: User #{current_user&.id} - #{details.to_json}"
  end

  # Check for suspicious activity patterns
  def check_suspicious_activity
    # Implement rate limiting, unusual access patterns, etc.
    # This is a placeholder for future implementation
  end
end
