class Admin::SubscriptionsController < ApplicationController
  before_action :require_super_admin
  skip_before_action :check_tenant_subscription, only: [:index, :renew, :suspend, :activate, :grant_trial]

  def index
    @tenants = Tenant.includes(:company_setting)
                     .order(subscription_expires_at: :asc)
                     .page(params[:page]).per(20)

    # Estatísticas
    @total_tenants = Tenant.count
    @active_count = Tenant.active_subscriptions.count
    @trial_count = Tenant.trial_subscriptions.count
    @expired_count = Tenant.expired_subscriptions.count
    @expiring_soon_count = Tenant.expiring_soon(7).count

    # Filtros
    if params[:status].present?
      @tenants = @tenants.where(subscription_status: params[:status])
    end

    if params[:expiring_soon] == 'true'
      @tenants = @tenants.where('subscription_expires_at BETWEEN ? AND ?', Time.current, 7.days.from_now)
                         .where(subscription_status: ['active', 'trial'])
    end
  end

  def renew
    @tenant = Tenant.find(params[:id])
    months = params[:months].to_i
    months = 1 if months <= 0

    @tenant.renew_subscription!(months)

    # Aqui você pode adicionar lógica para registrar o pagamento
    # Payment.create!(tenant: @tenant, amount: calculate_price(months), months: months)

    redirect_to admin_subscriptions_path, notice: "Subscrição do #{@tenant.name} renovada por #{months} mês(es). Nova data de expiração: #{@tenant.subscription_expires_at.strftime('%d/%m/%Y')}"
  rescue StandardError => e
    redirect_to admin_subscriptions_path, alert: "Erro ao renovar subscrição: #{e.message}"
  end

  def suspend
    @tenant = Tenant.find(params[:id])
    @tenant.suspend_subscription!

    redirect_to admin_subscriptions_path, alert: "#{@tenant.name} foi suspenso. Os usuários não poderão acessar o sistema."
  rescue StandardError => e
    redirect_to admin_subscriptions_path, alert: "Erro ao suspender: #{e.message}"
  end

  def activate
    @tenant = Tenant.find(params[:id])
    @tenant.activate_subscription!

    redirect_to admin_subscriptions_path, notice: "#{@tenant.name} foi ativado com sucesso."
  rescue StandardError => e
    redirect_to admin_subscriptions_path, alert: "Erro ao ativar: #{e.message}"
  end

  def grant_trial
    @tenant = Tenant.find(params[:id])
    days = params[:days].to_i
    days = 30 if days <= 0

    @tenant.update!(
      subscription_status: 'trial',
      subscription_expires_at: Time.current + days.days
    )

    redirect_to admin_subscriptions_path, notice: "#{@tenant.name} recebeu #{days} dias de trial."
  rescue StandardError => e
    redirect_to admin_subscriptions_path, alert: "Erro ao conceder trial: #{e.message}"
  end

  private

  def require_super_admin
    unless current_user&.super_admin?
      redirect_to root_path, alert: 'Acesso negado. Apenas Super Administradores podem acessar esta área.'
    end
  end

  def calculate_price(months)
    base_price = 50_000 # AOA por mês

    # Descontos para planos longos
    discount = case months
               when 12..Float::INFINITY then 0.20 # 20% desconto anual
               when 6..11 then 0.15 # 15% desconto semestral
               when 3..5 then 0.10 # 10% desconto trimestral
               else 0.0
               end

    total = base_price * months
    total * (1 - discount)
  end
end
