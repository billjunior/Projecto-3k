require 'prawn'
require 'prawn/table'

class PricingAnalysisReportPdf < BasePdf
  def initialize(tenant, start_date, end_date, data)
    super(tenant)
    @start_date = start_date
    @end_date = end_date
    @data = data || {}
  end

  def generate
    Prawn::Document.new(page_size: 'A4', margin: 40) do |pdf|
      # Company Header with Logo
      add_company_header(pdf)

      pdf.move_down 20

      # Title
      pdf.font_size 18
      pdf.text "Relatório de Análise de Preços", align: :center, style: :bold
      pdf.move_down 5

      pdf.font_size 12
      pdf.text "Período: #{@start_date.strftime('%d/%m/%Y')} a #{@end_date.strftime('%d/%m/%Y')}", align: :center
      pdf.move_down 20

      # Summary Metrics
      pdf.font_size 14
      pdf.text "Resumo Executivo", style: :bold
      pdf.move_down 10

      summary_data = [
        ["Total de Avisos", (@data[:total_warnings] || 0).to_s],
        ["Perda Total de Lucro", format_currency(@data[:total_profit_loss] || 0)],
        ["Défice Médio de Margem", "#{sprintf('%.2f', @data[:avg_margin_deficit] || 0)}%"],
        ["Total de Descontos Aplicados", format_currency(@data[:total_discount_amount] || 0)]
      ]

      pdf.table(summary_data,
        cell_style: { borders: [], padding: [8, 10], size: 11 },
        column_widths: [250, 250],
        row_colors: ["F8F9FA", "FFFFFF"]) do |table|
        table.column(0).font_style = :bold
        table.column(0).background_color = "E9ECEF"
        table.column(1).align = :right
      end

      pdf.move_down 20

      # Warnings by Type
      if @data[:warnings_by_type].present?
        pdf.font_size 14
        pdf.text "Avisos por Tipo", style: :bold
        pdf.move_down 10

        type_data = @data[:warnings_by_type].map do |type, count|
          type_name = type == 'below_margin' ? 'Margem Baixa' : 'Desconto Alto'
          [type_name, count.to_s]
        end

        pdf.table(type_data,
          cell_style: { borders: [:bottom], border_width: 0.5, padding: 5 },
          column_widths: [300, 200]) do |table|
          table.column(0).font_style = :bold
          table.column(1).align = :right
        end

        pdf.move_down 20
      end

      # Warnings by Severity
      if @data[:warnings_by_severity].present?
        pdf.font_size 14
        pdf.text "Avisos por Severidade", style: :bold
        pdf.move_down 10

        severity_data = @data[:warnings_by_severity].map do |severity, count|
          severity_name = case severity
                          when 'low' then 'Baixa'
                          when 'medium' then 'Média'
                          when 'high' then 'Alta'
                          else severity.to_s.capitalize
                          end
          [severity_name, count.to_s]
        end

        pdf.table(severity_data,
          cell_style: { borders: [:bottom], border_width: 0.5, padding: 5 },
          column_widths: [300, 200]) do |table|
          table.column(0).font_style = :bold
          table.column(1).align = :right
        end

        pdf.move_down 20
      end

      # Top Loss Warnings
      if @data[:top_loss_warnings].present? && @data[:top_loss_warnings].respond_to?(:any?) && @data[:top_loss_warnings].any?
        pdf.start_new_page

        pdf.font_size 14
        pdf.text "Top 10 Documentos com Maior Perda de Lucro", style: :bold
        pdf.move_down 10

        table_data = [["Documento", "Cliente", "Margem Esp.", "Margem Real", "Perda"]]
        @data[:top_loss_warnings].each do |warning|
          next unless warning.warnable.present? && warning.warnable.customer.present?

          doc_type = warning.warnable.is_a?(Estimate) ? "Orçamento" : "Fatura"
          doc_number = warning.warnable.is_a?(Estimate) ? warning.warnable.estimate_number : warning.warnable.invoice_number

          table_data << [
            "#{doc_type}\n#{doc_number || 'N/A'}",
            warning.warnable.customer.name || 'N/A',
            "#{sprintf('%.0f', warning.expected_margin || 0)}%",
            "#{sprintf('%.2f', warning.actual_margin || 0)}%",
            format_currency(warning.profit_loss || 0)
          ]
        end

        if table_data.length > 1
          pdf.table(table_data,
            header: true,
            cell_style: { size: 9, padding: 5 },
            column_widths: [100, 150, 70, 70, 110]) do |table|
            table.row(0).font_style = :bold
            table.row(0).background_color = 'E9ECEF'
            table.column(2..4).align = :right
          end

          pdf.move_down 20
        end
      end

      # Problem Estimates
      if @data[:problem_estimates].present? && @data[:problem_estimates].respond_to?(:any?) && @data[:problem_estimates].any?
        pdf.start_new_page if pdf.cursor < 200

        pdf.font_size 14
        pdf.text "Orçamentos com Descontos / Margem Baixa (Top 10)", style: :bold
        pdf.move_down 10

        table_data = [["Número", "Cliente", "Data", "Desconto", "Valor Total"]]
        @data[:problem_estimates].each do |estimate|
          next unless estimate.present? && estimate.customer.present?

          discount = estimate.discount_percentage.present? && estimate.discount_percentage > 0 ?
                     "#{sprintf('%.2f', estimate.discount_percentage)}%" : "-"

          table_data << [
            estimate.estimate_number || 'N/A',
            estimate.customer.name || 'N/A',
            estimate.created_at&.strftime('%d/%m/%Y') || 'N/A',
            discount,
            format_currency(estimate.total_value || 0)
          ]
        end

        if table_data.length > 1
          pdf.table(table_data,
            header: true,
            cell_style: { size: 9, padding: 5 },
            column_widths: [80, 150, 70, 70, 130]) do |table|
            table.row(0).font_style = :bold
            table.row(0).background_color = 'E9ECEF'
            table.column(3..4).align = :right
          end

          pdf.move_down 20
        end
      end

      # Problem Invoices
      if @data[:problem_invoices].present? && @data[:problem_invoices].respond_to?(:any?) && @data[:problem_invoices].any?
        pdf.start_new_page if pdf.cursor < 200

        pdf.font_size 14
        pdf.text "Faturas com Descontos / Margem Baixa (Top 10)", style: :bold
        pdf.move_down 10

        table_data = [["Número", "Cliente", "Data", "Desconto", "Valor Total"]]
        @data[:problem_invoices].each do |invoice|
          next unless invoice.present? && invoice.customer.present?

          discount = invoice.discount_percentage.present? && invoice.discount_percentage > 0 ?
                     "#{sprintf('%.2f', invoice.discount_percentage)}%" : "-"

          table_data << [
            invoice.invoice_number || 'N/A',
            invoice.customer.name || 'N/A',
            invoice.invoice_date&.strftime('%d/%m/%Y') || 'N/A',
            discount,
            format_currency(invoice.total_value || 0)
          ]
        end

        if table_data.length > 1
          pdf.table(table_data,
            header: true,
            cell_style: { size: 9, padding: 5 },
            column_widths: [80, 150, 70, 70, 130]) do |table|
            table.row(0).font_style = :bold
            table.row(0).background_color = 'E9ECEF'
            table.column(3..4).align = :right
          end
        end
      end

      # Footer
      pdf.number_pages "Página <page> de <total>",
                       at: [pdf.bounds.right - 150, 0],
                       align: :right,
                       size: 8
    end.render
  end
end
