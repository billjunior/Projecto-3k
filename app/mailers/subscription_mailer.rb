class SubscriptionMailer < ApplicationMailer
  # Email enviado quando a subscrição expira
  def expired_notification(tenant)
    @tenant = tenant
    @company_settings = tenant.company_setting

    # Enviar para todos os admins do tenant
    admin_emails = tenant.users.where(role: ['admin', 'super_admin']).pluck(:email)

    mail(
      to: admin_emails,
      subject: "Subscrição Expirada - #{@tenant.name} - CRM 3K"
    )
  end

  # Email enviado quando a subscrição está próxima de expirar
  def expiring_soon_notification(tenant)
    @tenant = tenant
    @company_settings = tenant.company_setting
    @days_remaining = tenant.days_remaining

    # Enviar para todos os admins do tenant
    admin_emails = tenant.users.where(role: ['admin', 'super_admin']).pluck(:email)

    mail(
      to: admin_emails,
      subject: "Subscrição Expira em #{@days_remaining} Dias - #{@tenant.name} - CRM 3K"
    )
  end

  # Email enviado quando a subscrição é renovada
  def renewed_notification(tenant)
    @tenant = tenant
    @company_settings = tenant.company_setting

    # Enviar para todos os admins do tenant
    admin_emails = tenant.users.where(role: ['admin', 'super_admin']).pluck(:email)

    mail(
      to: admin_emails,
      subject: "Subscrição Renovada com Sucesso - #{@tenant.name} - CRM 3K"
    )
  end
end
