require 'prawn'
require 'prawn/table'

# Suppress Prawn internationalization warning
Prawn::Fonts::AFM.hide_m17n_warning = true

class EstimatePdf < BasePdf
  def initialize(estimate)
    super(estimate.tenant)
    @estimate = estimate
  end

  def generate
    Prawn::Document.new(page_size: 'A4', margin: 40) do |pdf|
      # Company Header with Logo and Information
      add_company_header(pdf)

      pdf.move_down 30

      # Estimate Title and Number
      add_estimate_title(pdf)

      pdf.move_down 20

      # Estimate and Customer Information (Side by Side)
      add_estimate_info(pdf)

      pdf.move_down 20

      # Estimate Items Table
      add_items_table(pdf)

      pdf.move_down 20

      # Validity and Notes
      add_validity_notes(pdf)

      # Footer
      add_standard_footer(pdf)
    end.render
  end

  private

  def add_estimate_title(pdf)
    pdf.font_size 24
    pdf.text "ORÇAMENTO", align: :center, style: :bold
    pdf.move_down 5

    pdf.font_size 12
    pdf.text "Orçamento Nº #{@estimate.estimate_number}", align: :center
  end

  def add_estimate_info(pdf)
    pdf.font_size 10

    # Create two-column layout
    estimate_data = [
      ["Data do Orçamento:", @estimate.created_at.strftime('%d/%m/%Y')],
      ["Válido até:", @estimate.valid_until ? @estimate.valid_until.strftime('%d/%m/%Y') : "N/A"],
      ["Status:", translate_status(@estimate.status)],
      ["Criado por:", @estimate.created_by_user&.email || "Sistema"]
    ]

    customer_data = [
      ["Cliente:", @estimate.customer.name],
      ["Tipo:", @estimate.customer.customer_type == 'particular' ? 'Particular' : 'Empresa'],
      ["Telefone:", @estimate.customer.phone || "N/A"],
      ["Email:", @estimate.customer.email || "N/A"]
    ]

    # Left column - Estimate info
    pdf.bounding_box([0, pdf.cursor], width: 250) do
      pdf.text "Informações do Orçamento", style: :bold
      pdf.move_down 5
      pdf.table(estimate_data, cell_style: { borders: [], padding: 2 })
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
    pdf.text "Itens do Orçamento", style: :bold
    pdf.move_down 10

    pdf.font_size 9
    table_data = [["#", "Descrição", "Qtd.", "Preço Unit.", "Subtotal"]]

    @estimate.estimate_items.each_with_index do |item, index|
      table_data << [
        (index + 1).to_s,
        item.product&.name || "Item",
        format_number(item.quantity),
        format_currency(item.unit_price),
        format_currency(item.subtotal)
      ]
    end

    # Add Total Row
    table_data << ["", "", "", "TOTAL:", format_currency(@estimate.total_value)]

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

  def add_validity_notes(pdf)
    pdf.font_size 10

    # Validity period
    if @estimate.valid_until
      validity_info = [
        ["Data de Criação:", @estimate.created_at.strftime('%d/%m/%Y')],
        ["Válido até:", @estimate.valid_until.strftime('%d/%m/%Y')]
      ]

      pdf.text "Validade", style: :bold
      pdf.move_down 5
      pdf.table(validity_info,
        cell_style: { borders: [:bottom], border_width: 0.5, padding: 5 },
        column_widths: [200, 300])
    end

    # Notes if any
    if @estimate.notes.present?
      pdf.move_down 15
      pdf.text "Observações:", style: :bold
      pdf.move_down 5
      pdf.text @estimate.notes, size: 9
    end
  end

  def translate_status(status)
    {
      'rascunho' => 'Rascunho',
      'pendente_aprovacao' => 'Pendente Aprovação',
      'aprovado' => 'Aprovado',
      'recusado' => 'Recusado',
      'expirado' => 'Expirado'
    }[status] || status.capitalize
  end
end
