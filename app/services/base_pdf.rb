require 'prawn'
require 'prawn/table'

class BasePdf
  def initialize(tenant)
    @tenant = tenant
    @company_settings = tenant.company_setting
  end

  protected

  # Standard company header with logo for all reports
  def add_company_header(pdf)
    # Logo (if exists)
    if @company_settings&.logo&.attached?
      begin
        logo_path = ActiveStorage::Blob.service.path_for(@company_settings.logo.key)
        if File.exist?(logo_path)
          pdf.image logo_path, width: 120, height: 60, position: :center
          pdf.move_down 10
        end
      rescue => e
        Rails.logger.error "Failed to add logo to PDF: #{e.message}"
      end
    end

    # Company Name
    pdf.font_size 18
    pdf.text (@company_settings&.company_name || @tenant.name), align: :center, style: :bold
    pdf.move_down 5

    # Company Tagline
    if @company_settings&.company_tagline.present?
      pdf.font_size 10
      pdf.text @company_settings.company_tagline, align: :center, style: :italic
      pdf.move_down 5
    end

    # Contact Information
    contact_info = []
    contact_info << @company_settings.address if @company_settings&.address.present?
    contact_info << "Tel: #{@company_settings.phone}" if @company_settings&.phone.present?
    contact_info << "Email: #{@company_settings.email}" if @company_settings&.email.present?

    if contact_info.any?
      pdf.font_size 9
      pdf.text contact_info.join(" | "), align: :center
    end

    # Divider Line
    pdf.move_down 10
    pdf.stroke_horizontal_rule
  end

  # Standard footer with generation timestamp
  def add_standard_footer(pdf)
    pdf.move_to_bottom
    pdf.move_up 20
    pdf.font_size 8
    pdf.text "Documento gerado em #{Time.current.strftime('%d/%m/%Y às %H:%M')}",
      align: :center, color: '999999'
    pdf.text "#{@company_settings&.company_name || @tenant.name} - Sistema de Gestão",
      align: :center, color: '999999'
  end

  # Currency formatting helper
  def format_currency(value)
    formatted = sprintf("%.2f", (value || 0).round(2))
    parts = formatted.split('.')
    parts[0].gsub!(/(\d)(?=(\d{3})+(?!\d))/, "\\1.")
    "#{parts.join(',')} AOA"
  end

  # Number formatting helper
  def format_number(value)
    sprintf("%.2f", value).sub('.', ',')
  end
end
