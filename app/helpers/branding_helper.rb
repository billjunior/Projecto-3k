module BrandingHelper
  def tenant_logo_tag(options = {})
    return '' unless current_user&.tenant

    company_setting = current_user.tenant.company_setting
    if company_setting&.logo&.attached?
      image_tag company_setting.logo, options.merge(alt: company_setting.company_name, class: 'tenant-logo')
    else
      ''
    end
  end

  def tenant_name
    return 'CRM 3K' unless current_user&.tenant
    current_user.tenant.company_setting&.company_name || 'CRM 3K'
  end

  def tenant_favicon_tag
    return '' unless current_user&.tenant

    company_setting = current_user.tenant.company_setting
    if company_setting&.logo&.attached?
      favicon_link_tag url_for(company_setting.logo)
    end
  end

  def tenant_color(type = :primary)
    return default_color(type) unless current_user&.tenant
    current_user.tenant.settings.dig("#{type}_color") || default_color(type)
  end

  def tenant_setting(key)
    return nil unless current_user&.tenant
    current_user.tenant.settings[key.to_s]
  end

  private

  def default_color(type)
    case type
    when :primary then '#007bff'
    when :secondary then '#6c757d'
    else '#000000'
    end
  end
end
