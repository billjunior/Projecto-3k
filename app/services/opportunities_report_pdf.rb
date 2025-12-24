require 'prawn'
require 'prawn/table'

class OpportunitiesReportPdf < BasePdf
  def initialize(tenant, opportunities)
    super(tenant)
    @opportunities = opportunities
  end

  def generate
    Prawn::Document.new(page_size: 'A4', margin: 40) do |pdf|
      # Company Header with Logo
      add_company_header(pdf)

      pdf.move_down 20

      pdf.font_size 16
      pdf.text "Relatório de Oportunidades", align: :center, style: :bold
      pdf.move_down 5

      pdf.font_size 12
      pdf.text "Gerado em #{Time.current.strftime('%d/%m/%Y')}", align: :center
      pdf.move_down 20

      # Summary
      pdf.font_size 10
      opportunities_by_stage = @opportunities.group(:stage).count
      total_value = @opportunities.sum(:value) || 0
      weighted_value = @opportunities.sum { |o| (o.value || 0) * (o.probability || 0) / 100.0 }
      won_count = @opportunities.where(stage: 'won').count
      conversion_rate = @opportunities.any? ? (won_count.to_f / @opportunities.count * 100) : 0

      summary_data = [
        ["Total de Oportunidades:", @opportunities.count.to_s],
        ["Valor Total:", format_currency(total_value)],
        ["Valor Ponderado:", format_currency(weighted_value)],
        ["Taxa de Conversão:", "#{sprintf('%.1f', conversion_rate)}%"],
        ["Oportunidades Ganhas:", won_count.to_s],
        ["Oportunidades Perdidas:", opportunities_by_stage['lost'].to_i.to_s]
      ]

      pdf.table(summary_data,
        cell_style: { borders: [:bottom], border_width: 0.5, padding: 5 },
        column_widths: [200, 300]) do |table|
        table.column(0).font_style = :bold
      end

      pdf.move_down 20

      # Opportunities by stage
      pdf.font_size 12
      pdf.text "Oportunidades por Estágio", style: :bold
      pdf.move_down 5

      stage_data = [["Estágio", "Quantidade", "Valor Total"]]
      opportunities_by_stage.each do |stage, count|
        stage_value = @opportunities.where(stage: stage).sum(:value)
        stage_data << [
          translate_stage(stage),
          count.to_s,
          format_currency(stage_value)
        ]
      end

      pdf.table(stage_data,
        header: true,
        cell_style: { padding: 5, size: 9 },
        column_widths: [200, 100, 200]) do |table|
        table.row(0).font_style = :bold
        table.row(0).background_color = 'DDDDDD'
      end

      pdf.move_down 20

      # Opportunities table
      if @opportunities.any?
        pdf.font_size 14
        pdf.text "Detalhes das Oportunidades", style: :bold
        pdf.move_down 10

        pdf.font_size 7
        table_data = [["Cliente", "Título", "Estágio", "Valor", "Prob.", "Ponderado", "Responsável"]]

        @opportunities.order(created_at: :desc).limit(50).each do |opp|
          weighted = (opp.value || 0) * (opp.probability || 0) / 100.0
          table_data << [
            opp.customer.name.truncate(20),
            opp.title.truncate(25),
            translate_stage(opp.stage).truncate(12),
            format_currency(opp.value || 0),
            "#{opp.probability || 0}%",
            format_currency(weighted),
            opp.assigned_to_user&.email&.truncate(20) || "N/A"
          ]
        end

        pdf.table(table_data,
          header: true,
          cell_style: { padding: 3, size: 7 },
          column_widths: [65, 85, 60, 60, 35, 60, 70]) do |table|
          table.row(0).font_style = :bold
          table.row(0).background_color = 'DDDDDD'
        end
      else
        pdf.text "Nenhuma oportunidade cadastrada.", style: :italic
      end

      # Footer
      add_standard_footer(pdf)
    end.render
  end

  private

  def translate_stage(stage)
    {
      'lead' => 'Lead',
      'qualified' => 'Qualificado',
      'proposal' => 'Proposta',
      'negotiation' => 'Negociação',
      'won' => 'Ganho',
      'lost' => 'Perdido'
    }[stage] || stage.capitalize
  end
end
