class LanSessionReportMailer < ApplicationMailer
  def monthly_report(tenant, month, year, recipient_email)
    @tenant = tenant
    @month = month
    @year = year
    @month_name = Date::MONTHNAMES[month]

    # Generate PDF
    pdf_service = LanSessionReportPdf.new(tenant, month, year)
    pdf_content = pdf_service.generate

    # Attach PDF
    attachments["relatorio_sessoes_#{@month_name}_#{year}.pdf"] = pdf_content

    # Calculate summary for email body
    @sessions = LanSession.where(
      'EXTRACT(MONTH FROM start_time) = ? AND EXTRACT(YEAR FROM start_time) = ?',
      month,
      year
    )
    @total_sessions = @sessions.count
    @active_sessions = @sessions.where(status: 'aberta').count
    @closed_sessions = @sessions.where(status: 'fechada').count

    closed_revenue = @sessions.where(status: 'fechada').sum(:total_value) || 0
    active_revenue = @sessions.where(status: 'aberta').sum { |s| s.current_value || 0 }
    @total_revenue = closed_revenue + active_revenue

    mail(
      to: recipient_email,
      subject: "Relatório Mensal de Sessões LAN - #{@month_name} #{year}"
    )
  end
end
