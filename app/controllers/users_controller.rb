class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :check_user_management_access
  before_action :set_user, only: [:edit, :update, :destroy, :reset_password, :lock_account, :unlock_account]

  def index
    @users = User.all.order(created_at: :desc)
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    @user.password = SecureRandom.hex(8)
    @user.skip_confirmation!

    if @user.save
      redirect_to users_path, notice: "Utilizador criado com sucesso. Palavra-passe temporária: #{@user.password}"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to users_path, notice: 'Utilizador atualizado com sucesso.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # Prevent deleting yourself
    if @user == current_user
      redirect_to users_path, alert: 'Não pode eliminar a sua própria conta.'
      return
    end

    # Prevent deleting the last super admin
    if @user.super_admin? && User.where(super_admin: true).count <= 1
      redirect_to users_path, alert: 'Não é possível eliminar o último Super Admin do sistema.'
      return
    end

    if @user.destroy
      redirect_to users_path, notice: 'Utilizador eliminado com sucesso.'
    else
      redirect_to users_path, alert: 'Erro ao eliminar utilizador.'
    end
  end

  def reset_password
    new_password = params[:new_password].presence || SecureRandom.hex(8)
    @user.password = new_password
    @user.password_confirmation = new_password

    if @user.save
      redirect_to users_path, notice: "Palavra-passe redefinida com sucesso. Nova palavra-passe: #{new_password}"
    else
      redirect_to users_path, alert: 'Erro ao redefinir palavra-passe.'
    end
  end

  def lock_account
    @user.lock_access!
    redirect_to users_path, notice: 'Conta bloqueada com sucesso.'
  end

  def unlock_account
    @user.unlock_access!
    redirect_to users_path, notice: 'Conta desbloqueada com sucesso.'
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :role, :department, :admin, :super_admin, :active)
  end

  def check_user_management_access
    unless current_user.can_manage_user_accounts?
      redirect_to root_path, alert: 'Acesso negado. Apenas Diretores podem gerir usuários.'
    end
  end
end
