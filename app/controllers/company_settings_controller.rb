class CompanySettingsController < ApplicationController
  before_action :check_admin_access
  before_action :set_company_settings

  def edit
  end

  def update
    if @company_settings.update(company_settings_params)
      redirect_to edit_company_settings_path, notice: 'Configurações atualizadas com sucesso.'
    else
      flash.now[:alert] = "Erro ao salvar: #{@company_settings.errors.full_messages.join(', ')}"
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
    @company_settings = current_user.tenant.company_setting
    unless @company_settings
      @company_settings = current_user.tenant.build_company_setting
      @company_settings.save(validate: false) # Create the record without validation
    end
  end

  def company_settings_params
    params.require(:company_setting).permit(
      :company_name, :address, :email, :phone, :iban, :company_tagline, :logo,
      :director_general_email, :financial_director_email, :default_profit_margin,
      :director_general_phone, :director_general_whatsapp,
      :financial_director_phone, :financial_director_whatsapp,
      phones: [], emails: [], ibans: [],
      bank_accounts: [:bank_name, :account_number, :iban, :swift, :notes]
    )
  end
end
