# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # Skip callbacks that might interfere with login
  skip_before_action :set_current_tenant, only: [:new, :create]
  skip_before_action :check_subscription_status, only: [:new, :create]
  skip_before_action :check_crm_access, only: [:new, :create]

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  # def create
  #   super
  # end

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
