require 'prawn'
require 'prawn/table'

class SalesReportPdf < BasePdf
  def initialize(tenant, start_date, end_date)
    super(tenant)
    @start_date = start_date
    @end_date = end_date
    @invoices = Invoice.where(invoice_date: @start_date..@end_date)
    @estimates = Estimate.where(created_at: @start_date..@end_date)
    @jobs = Job.where(created_at: @start_date..@end_date)
  end

  def generate
    Prawn::Document.new(page_size: 'A4', margin: 40) do |pdf|
      # Company Header with Logo
      add_company_header(pdf)

      pdf.move_down 20

      pdf.font_size 16
      pdf.text "Relatório Geral de Vendas", align: :center, style: :bold
      pdf.move_down 5

      pdf.font_size 12
      pdf.text "Período: #{@start_date.strftime('%d/%m/%Y')} a #{@end_date.strftime('%d/%m/%Y')}", align: :center
      pdf.move_down 20

      # Summary - Invoices
      pdf.font_size 12
      pdf.text "Resumo de Faturas", style: :bold
      pdf.move_down 5

      total_sales = @invoices.sum(:total_value) || 0
      paid_sales = @invoices.where(status: 'paga').sum(:total_value) || 0

      pdf.font_size 10
      invoices_summary = [
        ["Total de Vendas:", format_currency(total_sales)],
        ["Vendas Pagas:", format_currency(paid_sales)],
        ["Número de Faturas:", @invoices.count.to_s],
        ["Faturas Pagas:", @invoices.where(status: 'paga').count.to_s]
      ]

      pdf.table(invoices_summary,
        cell_style: { borders: [:bottom], border_width: 0.5, padding: 5 },
        column_widths: [200, 300]) do |table|
        table.column(0).font_style = :bold
      end

      pdf.move_down 15

      # Summary - Estimates
      pdf.font_size 12
      pdf.text "Resumo de Orçamentos", style: :bold
      pdf.move_down 5

      estimates_approved = @estimates.where(status: 'aprovado')
      conversion_rate = @estimates.any? ? (estimates_approved.count.to_f / @estimates.count * 100) : 0

      pdf.font_size 10
      estimates_summary = [
        ["Total de Orçamentos:", @estimates.count.to_s],
        ["Orçamentos Aprovados:", estimates_approved.count.to_s],
        ["Taxa de Conversão:", "#{sprintf('%.1f', conversion_rate)}%"],
        ["Valor Total Aprovado:", format_currency(estimates_approved.sum(:total_value) || 0)]
      ]

      pdf.table(estimates_summary,
        cell_style: { borders: [:bottom], border_width: 0.5, padding: 5 },
        column_widths: [200, 300]) do |table|
        table.column(0).font_style = :bold
      end

      pdf.move_down 15

      # Summary - Jobs
      pdf.font_size 12
      pdf.text "Resumo de Trabalhos", style: :bold
      pdf.move_down 5

      jobs_completed = @jobs.where(status: 'concluído')

      pdf.font_size 10
      jobs_summary = [
        ["Total de Trabalhos:", @jobs.count.to_s],
        ["Trabalhos Concluídos:", jobs_completed.count.to_s],
        ["Trabalhos em Andamento:", @jobs.where(status: 'em_progresso').count.to_s]
      ]

      pdf.table(jobs_summary,
        cell_style: { borders: [:bottom], border_width: 0.5, padding: 5 },
        column_widths: [200, 300]) do |table|
        table.column(0).font_style = :bold
      end

      pdf.move_down 20

      # Top invoices
      if @invoices.any?
        pdf.font_size 14
        pdf.text "Maiores Vendas do Período", style: :bold
        pdf.move_down 10

        pdf.font_size 8
        top_invoices_data = [["Nº Fatura", "Cliente", "Data", "Valor", "Status"]]

        @invoices.order(total_value: :desc).limit(10).each do |invoice|
          top_invoices_data << [
            invoice.id.to_s.rjust(6, '0'),
            invoice.customer.name.truncate(40),
            invoice.invoice_date.strftime('%d/%m/%Y'),
            format_currency(invoice.total_value),
            translate_invoice_status(invoice.status)
          ]
        end

        pdf.table(top_invoices_data,
          header: true,
          cell_style: { padding: 4, size: 8 },
          column_widths: [70, 160, 70, 90, 125]) do |table|
          table.row(0).font_style = :bold
          table.row(0).background_color = 'DDDDDD'
        end
      end

      # Footer
      add_standard_footer(pdf)
    end.render
  end

  private

  def translate_invoice_status(status)
    {
      'pendente' => 'Pendente',
      'paga' => 'Paga',
      'parcial' => 'Parcial',
      'vencida' => 'Vencida',
      'cancelada' => 'Cancelada'
    }[status] || status.capitalize
  end
end
