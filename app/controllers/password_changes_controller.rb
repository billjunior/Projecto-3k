class PasswordChangesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show, :update]
  skip_before_action :set_current_tenant, only: [:show, :update]
  skip_before_action :check_tenant_subscription, only: [:show, :update]
  skip_before_action :check_crm_access, only: [:show, :update]
  layout 'devise'

  # GET /change_password
  def show
    @user = User.find_by(email: session[:pending_password_change_email])
    @reason = session[:password_change_reason] || 'troca obrigatória'

    if @user.nil?
      redirect_to new_user_session_path, alert: 'Sessão expirada. Por favor, faça login novamente.'
    elsif !@user.needs_password_change?
      redirect_to new_user_session_path, notice: 'Você já alterou sua senha. Por favor, faça login.'
    end
  end

  # PUT /change_password
  def update
    @user = User.find_by(email: session[:pending_password_change_email])
    @reason = session[:password_change_reason] || 'troca obrigatória'

    if @user.nil?
      redirect_to new_user_session_path, alert: 'Sessão expirada. Por favor, faça login novamente.' and return
    end

    if params[:user][:password].blank?
      flash.now[:alert] = 'A senha não pode estar em branco.'
      render :show and return
    end

    if params[:user][:password] != params[:user][:password_confirmation]
      flash.now[:alert] = 'As senhas não correspondem.'
      render :show and return
    end

    # Try to update password - model validations will check complexity
    if @user.update(password: params[:user][:password], password_confirmation: params[:user][:password_confirmation])
      @user.mark_password_changed!
      session.delete(:pending_password_change_email)
      session.delete(:password_change_reason)

      # Sign out privileged users so they login again with new password
      if @user.privileged_user?
        redirect_to new_user_session_path, notice: 'Senha alterada com sucesso! Por favor, faça login com sua nova senha.'
      else
        # Regular users can sign in directly
        sign_in(@user)
        redirect_to after_sign_in_path_for(@user), notice: 'Senha alterada com sucesso!'
      end
    else
      flash.now[:alert] = @user.errors.full_messages.join('<br>').html_safe
      render :show
    end
  end
end
