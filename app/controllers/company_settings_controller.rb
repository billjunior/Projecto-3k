class CompanySettingsController < ApplicationController
  before_action :check_admin_access
  before_action :set_company_settings

  def edit
  end

  def update
    if @company_settings.update(company_settings_params)
      redirect_to edit_company_settings_path, notice: 'Configurações atualizadas com sucesso.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def check_admin_access
    unless current_user.admin? || current_user.super_admin?
      redirect_to root_path, alert: 'Acesso negado. Apenas administradores podem acessar as configurações da empresa.'
    end
  end

  def set_company_settings
    @company_settings = current_user.tenant.company_setting || current_user.tenant.build_company_setting
  end

  def company_settings_params
    params.require(:company_setting).permit(
      :company_name, :address, :email, :phone, :iban, :company_tagline, :logo,
      phones: [], emails: [], ibans: [],
      bank_accounts: [:bank_name, :account_number, :iban, :swift, :notes]
    )
  end
end
