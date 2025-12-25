# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # Skip callbacks that might interfere with login
  skip_before_action :set_current_tenant, only: [:new, :create]
  skip_before_action :check_tenant_subscription, only: [:new, :create]
  skip_before_action :check_crm_access, only: [:new, :create]

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  def create
    super do |resource|
      next unless resource.persisted? && resource.needs_password_change?

      # Check if user needs to change password (first login or expired after 90 days)
      email = resource.email
      reason = resource.must_change_password? ? 'primeiro acesso' : 'palavra-passe expirada (90 dias)'
      sign_out(resource)

      if resource.privileged_user?
        # Privileged users (Director, Financial Director, Admin, Super Admin) change password in-app
        session[:pending_password_change_email] = email
        session[:password_change_reason] = reason
        redirect_to(change_password_path) && return
      else
        # Regular users receive email with reset link
        resource.send_reset_password_instructions
        redirect_to(new_user_session_path, alert: "Por favor, verifique o seu email para redefinir a sua palavra-passe (#{reason}).") && return
      end
    end
  end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end
end
