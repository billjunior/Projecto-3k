require 'prawn'
require 'prawn/table'

class InvoicesReportPdf < BasePdf
  def initialize(tenant, start_date, end_date)
    super(tenant)
    @start_date = start_date
    @end_date = end_date
    @invoices = fetch_invoices
  end

  def generate
    Prawn::Document.new(page_size: 'A4', margin: 40) do |pdf|
      # Company Header with Logo
      add_company_header(pdf)

      pdf.move_down 20

      pdf.font_size 16
      pdf.text "Relatório de Faturas", align: :center, style: :bold
      pdf.move_down 5

      pdf.font_size 12
      pdf.text "Período: #{@start_date.strftime('%d/%m/%Y')} a #{@end_date.strftime('%d/%m/%Y')}", align: :center
      pdf.move_down 20

      # Summary
      pdf.font_size 10
      summary_data = [
        ["Total Faturado:", format_currency(total_invoiced)],
        ["Total Pago:", format_currency(total_paid)],
        ["Valor Pendente:", format_currency(pending_amount)],
        ["Número de Faturas:", @invoices.count.to_s],
        ["Faturas Pagas:", invoices_by_status['paga'].to_i.to_s],
        ["Faturas Pendentes:", invoices_by_status['pendente'].to_i.to_s]
      ]

      pdf.table(summary_data,
        cell_style: { borders: [:bottom], border_width: 0.5, padding: 5 },
        column_widths: [200, 300]) do |table|
        table.column(0).font_style = :bold
      end

      pdf.move_down 20

      # Invoices table
      if @invoices.any?
        pdf.font_size 14
        pdf.text "Detalhes das Faturas", style: :bold
        pdf.move_down 10

        pdf.font_size 8
        table_data = [["Nº Fatura", "Cliente", "Data", "Vencimento", "Valor Total", "Pago", "Status"]]

        @invoices.order(invoice_date: :desc).each do |invoice|
          paid_amount = invoice.payments.sum(:amount)
          table_data << [
            invoice.id.to_s.rjust(6, '0'),
            invoice.customer.name.truncate(25),
            invoice.invoice_date.strftime('%d/%m/%Y'),
            invoice.due_date.strftime('%d/%m/%Y'),
            format_currency(invoice.total_value),
            format_currency(paid_amount),
            translate_status(invoice.status)
          ]
        end

        pdf.table(table_data,
          header: true,
          cell_style: { padding: 4, size: 8 },
          column_widths: [60, 110, 55, 60, 75, 75, 80]) do |table|
          table.row(0).font_style = :bold
          table.row(0).background_color = 'DDDDDD'
        end
      else
        pdf.text "Nenhuma fatura registrada neste período.", style: :italic
      end

      # Footer
      add_standard_footer(pdf)
    end.render
  end

  private

  def fetch_invoices
    Invoice.where(invoice_date: @start_date..@end_date).includes(:customer, :payments)
  end

  def total_invoiced
    @invoices.sum(:total_value) || 0
  end

  def total_paid
    @invoices.joins(:payments).sum('payments.amount') || 0
  end

  def pending_amount
    total_invoiced - total_paid
  end

  def invoices_by_status
    @invoices_by_status ||= @invoices.group(:status).count
  end

  def translate_status(status)
    {
      'pendente' => 'Pendente',
      'paga' => 'Paga',
      'parcial' => 'Parcial',
      'vencida' => 'Vencida',
      'cancelada' => 'Cancelada'
    }[status] || status.capitalize
  end
end
