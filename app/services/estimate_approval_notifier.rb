class EstimateApprovalNotifier
  def initialize(estimate)
    @estimate = estimate
    @company_setting = estimate.tenant.company_setting
  end

  def notify_directors
    return unless @company_setting

    notifications_sent = []

    # Notificar Director Geral
    if director_general_contacts.any?
      send_notifications_to(
        name: 'Director Geral',
        email: @company_setting.director_general_email,
        phone: @company_setting.director_general_phone,
        whatsapp: @company_setting.director_general_whatsapp
      )
      notifications_sent << 'Director Geral'
    end

    # Notificar Directora Financeira
    if financial_director_contacts.any?
      send_notifications_to(
        name: 'Directora Financeira',
        email: @company_setting.financial_director_email,
        phone: @company_setting.financial_director_phone,
        whatsapp: @company_setting.financial_director_whatsapp
      )
      notifications_sent << 'Directora Financeira'
    end

    notifications_sent
  end

  private

  def director_general_contacts
    [
      @company_setting.director_general_email,
      @company_setting.director_general_phone,
      @company_setting.director_general_whatsapp
    ].compact
  end

  def financial_director_contacts
    [
      @company_setting.financial_director_email,
      @company_setting.financial_director_phone,
      @company_setting.financial_director_whatsapp
    ].compact
  end

  def send_notifications_to(name:, email:, phone:, whatsapp:)
    # 1. Email
    if email.present?
      EstimateMailer.estimate_approved_notification(@estimate, email, name).deliver_later
      Rails.logger.info "Email de aprovação enviado para #{name}: #{email}"
    end

    # 2. WhatsApp
    if whatsapp.present?
      send_whatsapp_notification(whatsapp, name)
    end

    # 3. SMS
    if phone.present? && whatsapp.blank?
      send_sms_notification(phone, name)
    end
  end

  def send_whatsapp_notification(whatsapp, recipient_name)
    # Remove caracteres não numéricos
    clean_number = whatsapp.gsub(/\D/, '')

    # Adicionar código de país se não tiver (assumindo Angola +244)
    clean_number = "244#{clean_number}" unless clean_number.start_with?('244')

    message = whatsapp_message

    # Criar link do WhatsApp Web
    encoded_message = URI.encode_www_form_component(message)
    whatsapp_url = "https://wa.me/#{clean_number}?text=#{encoded_message}"

    # Log para acompanhamento (pode ser usado para envio automático via API)
    Rails.logger.info "WhatsApp para #{recipient_name}: #{whatsapp_url}"

    # TODO: Integrar com WhatsApp Business API para envio automático
    # Por enquanto, o link pode ser usado manualmente ou guardado para processamento

    # Guardar notificação pendente (opcional - pode criar uma tabela de notificações pendentes)
    store_pending_notification(
      type: 'whatsapp',
      recipient: whatsapp,
      recipient_name: recipient_name,
      message: message,
      url: whatsapp_url
    )
  end

  def send_sms_notification(phone, recipient_name)
    message = sms_message

    # Log para acompanhamento
    Rails.logger.info "SMS para #{recipient_name} (#{phone}): #{message}"

    # TODO: Integrar com serviço de SMS (Twilio, Nexmo, etc.)
    # Por enquanto, apenas loga a intenção de envio

    store_pending_notification(
      type: 'sms',
      recipient: phone,
      recipient_name: recipient_name,
      message: message
    )
  end

  def whatsapp_message
    <<~MESSAGE
      🎉 *ORÇAMENTO APROVADO*

      O orçamento *#{@estimate.estimate_number}* foi aprovado!

      📋 *Detalhes:*
      Cliente: #{@estimate.customer.name}
      Valor: #{format_currency(@estimate.total_value)} AOA
      Data de Aprovação: #{format_date(@estimate.approved_at)}
      Aprovado por: #{@estimate.approved_by}

      ✅ O cliente foi notificado por email.

      Ver orçamento: #{estimate_url}
    MESSAGE
  end

  def sms_message
    "ORÇAMENTO APROVADO: #{@estimate.estimate_number} - Cliente: #{@estimate.customer.name} - Valor: #{format_currency(@estimate.total_value)} AOA - Aprovado por: #{@estimate.approved_by}"
  end

  def format_currency(value)
    return '0,00' if value.nil?

    # Formatar com separador de milhar e decimal
    value.to_f.round(2).to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\\1.').gsub('.', ',', 1).gsub(/,(\d{3})/, '.\\1')
  end

  def format_date(datetime)
    return '' if datetime.nil?

    datetime.strftime('%d/%m/%Y às %H:%M')
  end

  def estimate_url
    # Gerar URL do orçamento (ajustar conforme o domínio da aplicação)
    Rails.application.routes.url_helpers.estimate_url(
      @estimate,
      host: ENV['APP_HOST'] || 'localhost:3000',
      protocol: ENV['APP_PROTOCOL'] || 'http'
    )
  rescue
    "#{ENV['APP_HOST'] || 'localhost:3000'}/estimates/#{@estimate.id}"
  end

  def store_pending_notification(type:, recipient:, recipient_name:, message:, url: nil)
    # Guardar em log estruturado ou tabela de auditoria
    Rails.logger.info({
      event: 'pending_notification',
      notification_type: type,
      estimate_id: @estimate.id,
      estimate_number: @estimate.estimate_number,
      recipient: recipient,
      recipient_name: recipient_name,
      message: message,
      url: url,
      timestamp: Time.current
    }.to_json)

    # TODO: Guardar em tabela de notificações pendentes para processamento assíncrono
    # PendingNotification.create!(
    #   notifiable: @estimate,
    #   notification_type: type,
    #   recipient: recipient,
    #   recipient_name: recipient_name,
    #   message: message,
    #   metadata: { url: url }
    # )
  end
end
