# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  # Skip multi-tenancy callbacks for registration
  skip_before_action :set_current_tenant, only: [:new, :create]
  skip_before_action :check_tenant_subscription, only: [:new, :create]
  skip_before_action :check_crm_access, only: [:new, :create]

  before_action :configure_sign_up_params, only: [:create]
  before_action :cleanup_unconfirmed_user, only: [:create]
  # before_action :configure_account_update_params, only: [:update]

  # GET /resource/sign_up
  # def new
  #   super
  # end

  # POST /resource
  def create
    # Temporarily disable tenant requirement for registration
    ActsAsTenant.without_tenant do
      build_resource(sign_up_params)

      # Assign default tenant (first available or master tenant)
      resource.tenant = Tenant.find_by(is_master: true) || Tenant.first

      resource.save
      yield resource if block_given?

      if resource.persisted?
        if resource.active_for_authentication?
          set_flash_message! :notice, :signed_up
          sign_up(resource_name, resource)
          respond_with resource, location: after_sign_up_path_for(resource)
        else
          set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
          expire_data_after_sign_in!
          respond_with resource, location: after_inactive_sign_up_path_for(resource)
        end
      else
        clean_up_passwords resource
        set_minimum_password_length
        respond_with resource
      end
    end
  end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  # def update
  #   super
  # end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle.
  # def cancel
  #   super
  # end

  protected

  # Clean up unconfirmed users with the same email before creating new one
  def cleanup_unconfirmed_user
    return unless params[:user] && params[:user][:email].present?

    ActsAsTenant.without_tenant do
      User.where(email: params[:user][:email], confirmed_at: nil)
          .where("created_at < ?", 1.hour.ago)
          .delete_all
    end
  end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
  end

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_account_update_params
  #   devise_parameter_sanitizer.permit(:account_update, keys: [:attribute])
  # end

  # The path used after sign up.
  def after_sign_up_path_for(resource)
    new_user_session_path
  end

  # The path used after sign up for inactive accounts.
  def after_inactive_sign_up_path_for(resource)
    new_user_session_path
  end
end
