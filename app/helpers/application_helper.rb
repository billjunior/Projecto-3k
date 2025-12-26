module ApplicationHelper
  MESES_PT = [
    nil,
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
  ].freeze

  def nome_mes(numero)
    MESES_PT[numero]
  end

  def opcoes_meses
    (1..12).map { |m| [MESES_PT[m], m] }
  end

  # Helper to get cached company settings
  # Performance fix: Cache company settings to avoid repeated DB queries
  def cached_company_settings
    return nil unless user_signed_in?

    Rails.cache.fetch("tenant_#{current_user.tenant_id}_company_settings", expires_in: 1.hour) do
      current_user.tenant.company_setting
    end
  end

  # Helper para exibir o logotipo do tenant
  # Opções:
  #   - size: :small (40px), :medium (80px), :large (120px) ou string customizada
  #   - fallback: texto a exibir se não houver logo (padrão: 'CRM 3K')
  #   - style: CSS inline adicional
  #   - class: classes CSS adicionais
  def tenant_logo(options = {})
    return nil unless user_signed_in?

    company_setting = cached_company_settings
    return options[:fallback] || 'CRM 3K' unless company_setting&.logo&.attached?

    size = case options[:size]
           when :small then '40px'
           when :medium then '80px'
           when :large then '120px'
           else options[:size] || '80px'
           end

    style = "max-height: #{size}; max-width: #{size == '40px' ? '150px' : '200px'}; object-fit: contain;"
    style += " #{options[:style]}" if options[:style].present?

    image_tag(
      company_setting.logo,
      alt: company_setting.company_name || 'Logo',
      style: style,
      class: options[:class]
    )
  end

  # Helper para exibir logo ou nome da empresa
  def tenant_branding(options = {})
    if user_signed_in? && cached_company_settings&.logo&.attached?
      tenant_logo(options)
    else
      company_name = user_signed_in? ? cached_company_settings&.company_name : nil
      company_name || options[:fallback] || 'CRM 3K'
    end
  end

  # Helper para criar link de WhatsApp clicável
  # Opções:
  #   - icon: exibir ícone do WhatsApp (padrão: true)
  #   - message: mensagem pré-definida (opcional)
  #   - class: classes CSS adicionais
  def whatsapp_link(phone_number, options = {})
    return nil if phone_number.blank?

    # Formatar número: remover espaços, parênteses, hífens, etc
    clean_number = phone_number.to_s.gsub(/[\s\-\(\)\.]/,  '')

    # Adicionar código do país (+244 para Angola) se não estiver presente
    # Aceita números com +244, 00244, ou 244 no início
    clean_number = "244#{clean_number}" unless clean_number.start_with?('244', '+244', '00244')
    clean_number = clean_number.gsub(/^\+/, '').gsub(/^00/, '')

    # Construir URL do WhatsApp
    whatsapp_url = "https://wa.me/#{clean_number}"
    whatsapp_url += "?text=#{ERB::Util.url_encode(options[:message])}" if options[:message].present?

    # Construir link HTML
    icon = options.fetch(:icon, true) ? content_tag(:i, '', class: 'bi bi-whatsapp text-success me-1') : ''
    css_class = "text-decoration-none #{options[:class]}".strip

    link_to whatsapp_url,
            target: '_blank',
            rel: 'noopener noreferrer',
            class: css_class,
            title: "Abrir WhatsApp com #{phone_number}" do
      concat icon
      concat phone_number
    end
  end

  # Helper para criar link de telefone clicável (tel:)
  # Opções:
  #   - icon: exibir ícone de telefone (padrão: true)
  #   - class: classes CSS adicionais
  def phone_link(phone_number, options = {})
    return nil if phone_number.blank?

    clean_number = phone_number.to_s.gsub(/[\s\-\(\)\.]/,  '')
    icon = options.fetch(:icon, true) ? content_tag(:i, '', class: 'bi bi-telephone me-1') : ''
    css_class = "text-decoration-none #{options[:class]}".strip

    link_to "tel:#{clean_number}",
            class: css_class,
            title: "Ligar para #{phone_number}" do
      concat icon
      concat phone_number
    end
  end
end
