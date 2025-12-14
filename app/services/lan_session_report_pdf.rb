require 'prawn'
require 'prawn/table'

class LanSessionReportPdf
  def initialize(tenant, month, year)
    @tenant = tenant
    @month = month
    @year = year
    @sessions = fetch_sessions
  end

  def generate
    Prawn::Document.new(page_size: 'A4', margin: 40) do |pdf|
      # Header
      pdf.font_size 20
      pdf.text @tenant.name, align: :center, style: :bold
      pdf.move_down 5

      pdf.font_size 16
      pdf.text "Relatório Mensal de Sessões LAN", align: :center
      pdf.move_down 5

      pdf.font_size 12
      pdf.text "#{Date::MONTHNAMES[@month]} de #{@year}", align: :center
      pdf.move_down 20

      # Summary
      pdf.font_size 10
      summary_data = [
        ["Total de Sessões:", @sessions.count.to_s],
        ["Sessões Ativas:", @sessions.where(status: 'aberta').count.to_s],
        ["Sessões Fechadas:", @sessions.where(status: 'fechada').count.to_s],
        ["Receita Total:", format_currency(total_revenue)],
        ["Receita de Sessões Ativas:", format_currency(active_revenue)],
        ["Receita de Sessões Fechadas:", format_currency(closed_revenue)]
      ]

      pdf.table(summary_data,
        cell_style: { borders: [:bottom], border_width: 0.5, padding: 5 },
        column_widths: [200, 300]) do |table|
        table.column(0).font_style = :bold
      end

      pdf.move_down 20

      # Sessions table
      if @sessions.any?
        pdf.font_size 14
        pdf.text "Detalhes das Sessões", style: :bold
        pdf.move_down 10

        pdf.font_size 8
        table_data = [["Máquina", "Cliente", "Início", "Fim", "Duração", "Valor", "Status"]]

        @sessions.order(start_time: :desc).each do |session|
          table_data << [
            session.lan_machine.name,
            session.customer&.name || "Anônimo",
            session.start_time.strftime('%d/%m %H:%M'),
            session.end_time ? session.end_time.strftime('%d/%m %H:%M') : "Em aberto",
            session.status == 'fechada' ? "#{session.total_minutes} min" : session.formatted_elapsed_time,
            format_currency(session.status == 'fechada' ? session.total_value : session.current_value),
            translate_status(session.status)
          ]
        end

        pdf.table(table_data,
          header: true,
          cell_style: { padding: 4, size: 8 },
          column_widths: [60, 100, 70, 70, 60, 80, 75]) do |table|
          table.row(0).font_style = :bold
          table.row(0).background_color = 'DDDDDD'
        end
      else
        pdf.text "Nenhuma sessão registrada neste período.", style: :italic
      end

      # Footer
      pdf.move_down 30
      pdf.font_size 8
      pdf.text "Relatório gerado automaticamente em #{Time.current.strftime('%d/%m/%Y às %H:%M')}",
        align: :center, color: '666666'
      pdf.text "CRM 3K - Sistema de Gestão", align: :center, color: '666666'
    end.render
  end

  private

  def fetch_sessions
    LanSession.where(
      'EXTRACT(MONTH FROM start_time) = ? AND EXTRACT(YEAR FROM start_time) = ?',
      @month,
      @year
    )
  end

  def total_revenue
    closed_revenue + active_revenue
  end

  def closed_revenue
    @sessions.where(status: 'fechada').sum(:total_value) || 0
  end

  def active_revenue
    @sessions.where(status: 'aberta').sum do |session|
      session.current_value || 0
    end
  end

  def format_currency(value)
    formatted = sprintf("%.2f", value.round(2))
    parts = formatted.split('.')
    parts[0].gsub!(/(\d)(?=(\d{3})+(?!\d))/, "\\1,")
    "#{parts.join('.')} AOA"
  end

  def translate_status(status)
    {
      'aberta' => 'Ativa',
      'fechada' => 'Fechada',
      'cancelada' => 'Cancelada'
    }[status] || status
  end
end
