class Admin::BaseController < ApplicationController
  before_action :require_super_admin

  private

  def require_super_admin
    unless current_user&.super_admin?
      redirect_to root_path, alert: 'Acesso negado. Apenas Super Administradores.'
    end
  end
end
