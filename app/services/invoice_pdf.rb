require 'prawn'
require 'prawn/table'

class InvoicePdf
  def initialize(invoice)
    @invoice = invoice
    @company_settings = invoice.tenant.company_setting
  end

  def generate
    Prawn::Document.new(page_size: 'A4', margin: 40) do |pdf|
      # Company Header with Logo and Information
      add_company_header(pdf)

      pdf.move_down 30

      # Invoice Title and Number
      pdf.font_size 24
      pdf.text "FATURA", align: :center, style: :bold
      pdf.move_down 5

      pdf.font_size 12
      pdf.text "Fatura Nº #{@invoice.id.to_s.rjust(6, '0')}", align: :center
      pdf.move_down 20

      # Invoice and Customer Information (Side by Side)
      add_invoice_customer_info(pdf)

      pdf.move_down 20

      # Invoice Items Table
      add_items_table(pdf)

      pdf.move_down 20

      # Payment Information
      add_payment_info(pdf)

      # Footer with Bank Information
      add_footer(pdf)
    end.render
  end

  private

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
    pdf.text (@company_settings&.company_name || @invoice.tenant.name), align: :center, style: :bold
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

  def add_invoice_customer_info(pdf)
    pdf.font_size 10

    # Create two-column layout
    invoice_data = [
      ["Data da Fatura:", @invoice.invoice_date.strftime('%d/%m/%Y')],
      ["Data de Vencimento:", @invoice.due_date.strftime('%d/%m/%Y')],
      ["Tipo:", @invoice.invoice_type == 'proforma' ? 'Proforma' : 'Definitiva'],
      ["Status:", translate_status(@invoice.status)]
    ]

    customer_data = [
      ["Cliente:", @invoice.customer.name],
      ["Tipo:", @invoice.customer.customer_type == 'particular' ? 'Particular' : 'Empresa'],
      ["Telefone:", @invoice.customer.phone || "N/A"],
      ["Email:", @invoice.customer.email || "N/A"]
    ]

    # Left column - Invoice info
    pdf.bounding_box([0, pdf.cursor], width: 250) do
      pdf.text "Informações da Fatura", style: :bold
      pdf.move_down 5
      pdf.table(invoice_data, cell_style: { borders: [], padding: 2 })
    end

    # Right column - Customer info
    pdf.bounding_box([280, pdf.cursor + 80], width: 250) do
      pdf.text "Informações do Cliente", style: :bold
      pdf.move_down 5
      pdf.table(customer_data, cell_style: { borders: [], padding: 2 })
    end
  end

  def add_items_table(pdf)
    pdf.font_size 12
    pdf.text "Itens da Fatura", style: :bold
    pdf.move_down 10

    pdf.font_size 9
    table_data = [["#", "Descrição", "Qtd.", "Preço Unit.", "Subtotal"]]

    @invoice.invoice_items.each_with_index do |item, index|
      table_data << [
        (index + 1).to_s,
        item.description || item.product&.name || "Item",
        format_number(item.quantity),
        format_currency(item.unit_price),
        format_currency(item.subtotal)
      ]
    end

    # Add Total Row
    table_data << ["", "", "", "TOTAL:", format_currency(@invoice.total_value)]

    pdf.table(table_data,
      header: true,
      cell_style: { padding: 6, size: 9 },
      column_widths: [30, 250, 60, 90, 85]) do |table|
      table.row(0).font_style = :bold
      table.row(0).background_color = 'EEEEEE'
      table.row(-1).font_style = :bold
      table.row(-1).column(3..4).background_color = 'FFC107'
    end
  end

  def add_payment_info(pdf)
    pdf.font_size 10

    # Payment summary
    payments_total = @invoice.payments.sum(:amount)
    balance = @invoice.total_value - payments_total

    pdf.text "Resumo de Pagamento", style: :bold
    pdf.move_down 5

    payment_summary = [
      ["Valor Total:", format_currency(@invoice.total_value)],
      ["Valor Pago:", format_currency(payments_total)],
      ["Saldo Restante:", format_currency(balance)]
    ]

    pdf.table(payment_summary,
      cell_style: { borders: [:bottom], border_width: 0.5, padding: 5 },
      column_widths: [400, 115]) do |table|
      table.column(0).font_style = :bold
      table.column(0).align = :right
      table.row(-1).background_color = balance > 0 ? 'FFEBEE' : 'E8F5E9'
    end

    # Notes if any
    if @invoice.notes.present?
      pdf.move_down 15
      pdf.text "Observações:", style: :bold
      pdf.move_down 5
      pdf.text @invoice.notes, size: 9
    end
  end

  def add_footer(pdf)
    # Bank Information if IBAN is set
    if @company_settings&.iban.present?
      pdf.move_down 20
      pdf.stroke_horizontal_rule
      pdf.move_down 10

      pdf.font_size 10
      pdf.text "Informações Bancárias para Pagamento", style: :bold, align: :center
      pdf.move_down 5
      pdf.font_size 9
      pdf.text "IBAN: #{@company_settings.iban}", align: :center

      pdf.move_down 3
      if @company_settings.company_name.present?
        pdf.text "Titular: #{@company_settings.company_name}", align: :center
      end
    end

    # Generation timestamp
    pdf.move_to_bottom
    pdf.move_up 20
    pdf.font_size 8
    pdf.text "Documento gerado em #{Time.current.strftime('%d/%m/%Y às %H:%M')}",
      align: :center, color: '999999'
  end

  def format_currency(value)
    formatted = sprintf("%.2f", (value || 0).round(2))
    parts = formatted.split('.')
    parts[0].gsub!(/(\d)(?=(\d{3})+(?!\d))/, "\\1.")
    "#{parts.join(',')} AOA"
  end

  def format_number(value)
    sprintf("%.2f", value).sub('.', ',')
  end

  def translate_status(status)
    {
      'pendente' => 'Pendente',
      'paga' => 'Paga',
      'parcial' => 'Parcialmente Paga',
      'vencida' => 'Vencida',
      'cancelada' => 'Cancelada'
    }[status] || status.capitalize
  end
end
