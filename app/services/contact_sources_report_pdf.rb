require 'prawn'
require 'prawn/table'

class ContactSourcesReportPdf < BasePdf
  def initialize(tenant, month, year, data)
    super(tenant)
    @month = month
    @year = year
    @data = data
    @start_date = Date.new(@year, @month, 1)
    @end_date = @start_date.end_of_month
  end

  def generate
    Prawn::Document.new(page_size: 'A4', margin: 40) do |pdf|
      # Company Header with Logo
      add_company_header(pdf)

      pdf.move_down 20

      pdf.font_size 16
      pdf.text "Relatório de Eficácia dos Meios de Contacto", align: :center, style: :bold
      pdf.move_down 5

      pdf.font_size 12
      pdf.text "#{Date::MONTHNAMES[@month]} de #{@year}", align: :center
      pdf.move_down 20

      # Summary
      pdf.font_size 10
      summary_data = [
        ["Total de Oportunidades:", @data[:total_opportunities].to_s],
        ["Oportunidades Ganhas:", @data[:total_won].to_s],
        ["Valor Total de Oportunidades:", format_currency(@data[:total_value] || 0)],
        ["Valor de Oportunidades Ganhas:", format_currency(@data[:total_won_value] || 0)],
        ["Total de Leads:", @data[:total_leads].to_s],
        ["Leads Convertidos:", @data[:total_converted].to_s]
      ]

      pdf.table(summary_data,
        cell_style: { borders: [:bottom], border_width: 0.5, padding: 5 },
        column_widths: [250, 250]) do |table|
        table.column(0).font_style = :bold
      end

      pdf.move_down 20

      # Opportunities by source
      if @data[:opportunities_by_source].any?
        pdf.font_size 14
        pdf.text "Oportunidades por Fonte de Contacto", style: :bold
        pdf.move_down 10

        pdf.font_size 8
        opp_table_data = [["Fonte", "Total Opp.", "Ganhas", "Taxa Conversão", "Valor Total", "Valor Ganho"]]

        @data[:opportunities_by_source].each do |source, count|
          won_count = @data[:opportunities_won_by_source][source] || 0
          conversion_rate = count > 0 ? (won_count.to_f / count * 100) : 0
          total_value = @data[:opportunities_value_by_source][source] || 0
          won_value = @data[:opportunities_won_value_by_source][source] || 0

          opp_table_data << [
            translate_source(source),
            count.to_s,
            won_count.to_s,
            "#{sprintf('%.1f', conversion_rate)}%",
            format_currency(total_value),
            format_currency(won_value)
          ]
        end

        pdf.table(opp_table_data,
          header: true,
          cell_style: { padding: 4, size: 8 },
          column_widths: [100, 65, 65, 75, 90, 90]) do |table|
          table.row(0).font_style = :bold
          table.row(0).background_color = 'DDDDDD'
        end
      end

      pdf.move_down 20

      # Leads by source
      if @data[:leads_by_source].any?
        pdf.font_size 14
        pdf.text "Leads por Fonte de Contacto", style: :bold
        pdf.move_down 10

        pdf.font_size 8
        leads_table_data = [["Fonte", "Total Leads", "Convertidos", "Taxa Conversão"]]

        @data[:leads_by_source].each do |source, count|
          converted_count = @data[:leads_converted_by_source][source] || 0
          conversion_rate = count > 0 ? (converted_count.to_f / count * 100) : 0

          leads_table_data << [
            translate_source(source),
            count.to_s,
            converted_count.to_s,
            "#{sprintf('%.1f', conversion_rate)}%"
          ]
        end

        pdf.table(leads_table_data,
          header: true,
          cell_style: { padding: 5, size: 9 },
          column_widths: [200, 100, 100, 115]) do |table|
          table.row(0).font_style = :bold
          table.row(0).background_color = 'DDDDDD'
        end
      end

      pdf.move_down 20

      # Best performing sources
      pdf.font_size 14
      pdf.text "Melhores Fontes de Contacto", style: :bold, color: '2E7D32'
      pdf.move_down 5

      pdf.font_size 9
      if @data[:opportunities_won_value_by_source].any?
        best_sources = @data[:opportunities_won_value_by_source].sort_by { |_, value| -value }.first(3)

        best_sources.each_with_index do |(source, value), index|
          won_count = @data[:opportunities_won_by_source][source] || 0
          total_count = @data[:opportunities_by_source][source] || 0
          conversion = total_count > 0 ? (won_count.to_f / total_count * 100) : 0

          pdf.text "#{index + 1}. #{translate_source(source)}: #{format_currency(value)} (#{won_count}/#{total_count} - #{sprintf('%.1f', conversion)}% conversão)"
          pdf.move_down 3
        end
      else
        pdf.text "Sem dados suficientes para análise.", style: :italic
      end

      # Footer
      add_standard_footer(pdf)
    end.render
  end

  private

  def translate_source(source)
    return "Não especificado" if source.blank?

    {
      'website' => 'Website',
      'referral' => 'Referência',
      'social_media' => 'Redes Sociais',
      'email_campaign' => 'Campanha Email',
      'phone' => 'Telefone',
      'walk_in' => 'Visita Presencial',
      'other' => 'Outro'
    }[source] || source.titleize
  end
end
