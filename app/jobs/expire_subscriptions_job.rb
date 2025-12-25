class ExpireSubscriptionsJob < ApplicationJob
  queue_as :default

  def perform
    # 1. Expirar subscrições que já venceram
    expire_overdue_subscriptions

    # 2. Notificar subscrições que expiram em 7 dias
    notify_expiring_soon(7)

    # 3. Notificar subscrições que expiram em 3 dias (último aviso)
    notify_expiring_soon(3)

    # 4. Notificar subscrições que expiram amanhã (aviso final)
    notify_expiring_soon(1)
  end

  private

  def expire_overdue_subscriptions
    # Encontrar tenants com subscrição ativa/trial mas já vencida
    expired_tenants = Tenant.where(subscription_status: ['active', 'trial'])
                            .where('subscription_expires_at < ?', Time.current)

    expired_count = 0

    expired_tenants.find_each do |tenant|
      tenant.expire_subscription!

      # Enviar email de notificação de expiração
      begin
        SubscriptionMailer.expired_notification(tenant).deliver_later
        Rails.logger.info "Email de expiração enviado para #{tenant.name}"
      rescue StandardError => e
        Rails.logger.error "Erro ao enviar email de expiração para #{tenant.name}: #{e.message}"
      end

      expired_count += 1
    end

    Rails.logger.info "ExpireSubscriptionsJob: #{expired_count} subscrições expiradas"
  end

  def notify_expiring_soon(days)
    # Encontrar tenants que expiram exatamente em X dias
    start_time = (Time.current + days.days).beginning_of_day
    end_time = (Time.current + days.days).end_of_day

    expiring_tenants = Tenant.where(subscription_status: ['active', 'trial'])
                             .where(subscription_expires_at: start_time..end_time)

    notified_count = 0

    expiring_tenants.find_each do |tenant|
      begin
        SubscriptionMailer.expiring_soon_notification(tenant).deliver_later
        Rails.logger.info "Email de aviso enviado para #{tenant.name} (expira em #{days} dias)"
        notified_count += 1
      rescue StandardError => e
        Rails.logger.error "Erro ao enviar email de aviso para #{tenant.name}: #{e.message}"
      end
    end

    Rails.logger.info "ExpireSubscriptionsJob: #{notified_count} avisos de expiração enviados (#{days} dias)"
  end
end
