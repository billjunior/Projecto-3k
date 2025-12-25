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

  # Helper para exibir o logotipo do tenant
  # Opções:
  #   - size: :small (40px), :medium (80px), :large (120px) ou string customizada
  #   - fallback: texto a exibir se não houver logo (padrão: 'CRM 3K')
  #   - style: CSS inline adicional
  #   - class: classes CSS adicionais
  def tenant_logo(options = {})
    return nil unless user_signed_in?

    company_setting = current_user.tenant.company_setting
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
    if user_signed_in? && current_user.tenant.company_setting&.logo&.attached?
      tenant_logo(options)
    else
      company_name = user_signed_in? ? current_user.tenant.company_setting&.company_name : nil
      company_name || options[:fallback] || 'CRM 3K'
    end
  end
end
