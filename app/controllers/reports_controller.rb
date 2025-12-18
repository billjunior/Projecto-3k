class ReportsController < ApplicationController
  before_action :check_admin_access

  def index
    # Dashboard de relatórios
  end

  def lan_sessions
    # Relatório de sessões LAN do Cyber Café
    @month = params[:month]&.to_i || Date.today.month
    @year = params[:year]&.to_i || Date.today.year

    @sessions = LanSession.where(
      'EXTRACT(MONTH FROM start_time) = ? AND EXTRACT(YEAR FROM start_time) = ?',
      @month,
      @year
    ).includes(:lan_machine, :customer).order(start_time: :desc)

    @total_sessions = @sessions.count
    @active_sessions = @sessions.where(status: 'aberta').count
    @closed_sessions = @sessions.where(status: 'fechada').count
    @total_revenue = @sessions.where(status: 'fechada').sum(:total_value)
    @active_revenue = @sessions.where(status: 'aberta').sum { |s| s.current_value || 0 }

    respond_to do |format|
      format.html
      format.pdf do
        pdf = LanSessionReportPdf.new(ActsAsTenant.current_tenant, @month, @year).generate
        send_data pdf, filename: "sessoes_lan_#{@month}_#{@year}.pdf",
                       type: 'application/pdf',
                       disposition: 'inline'
      end
    end
  end

  def invoices
    # Relatório de faturas
    @start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.today.beginning_of_month
    @end_date = params[:end_date] ? Date.parse(params[:end_date]) : Date.today.end_of_month

    # Base query for filtering
    invoices_scope = Invoice.where(invoice_date: @start_date..@end_date)

    @invoices = invoices_scope.includes(:customer, :payments)
                              .order(invoice_date: :desc)

    @total_invoiced = invoices_scope.sum(:total_value)
    @total_paid = invoices_scope.joins(:payments).sum('payments.amount')
    @pending_amount = @total_invoiced - @total_paid
    @invoices_by_status = invoices_scope.group(:status).count
  end

  def customers
    # Relatório de clientes
    @customers = Customer.includes(:invoices, :opportunities, :estimates)

    # Filtros
    if params[:customer_type].present?
      @customers = @customers.where(customer_type: params[:customer_type])
    end

    if params[:start_date].present? && params[:end_date].present?
      start_date = Date.parse(params[:start_date])
      end_date = Date.parse(params[:end_date])
      @customers = @customers.where(created_at: start_date..end_date)
    end

    @customers = @customers.order(created_at: :desc)

    @total_customers = @customers.count
    @customers_with_invoices = @customers.joins(:invoices).distinct.count
    @top_customers = @customers.joins(:invoices)
                               .select('customers.*, SUM(invoices.total_value) as total_spent')
                               .group('customers.id')
                               .order('total_spent DESC')
                               .limit(10)

    # Dados para gráficos
    @customers_by_type = Customer.group(:customer_type).count
  end

  def opportunities
    # Relatório de oportunidades (pipeline CRM)
    # Base query for filtering
    opportunities_scope = Opportunity.all

    @opportunities = opportunities_scope.includes(:customer, :assigned_to_user)
                                        .order(created_at: :desc)

    @opportunities_by_stage = opportunities_scope.group(:stage).count
    @total_value = opportunities_scope.sum(:value)
    @weighted_value = @opportunities.sum { |o| (o.value || 0) * (o.probability || 0) / 100.0 }
    @conversion_rate = opportunities_scope.won.count.to_f / opportunities_scope.count * 100 if opportunities_scope.any?
    @avg_deal_size = opportunities_scope.won.average(:value)
  end

  def sales
    # Relatório geral de vendas
    @start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.today.beginning_of_month
    @end_date = params[:end_date] ? Date.parse(params[:end_date]) : Date.today.end_of_month

    # Faturas do período
    @invoices = Invoice.where(invoice_date: @start_date..@end_date)
    @total_sales = @invoices.sum(:total_value)
    @paid_sales = @invoices.where(status: 'paga').sum(:total_value)

    # Orçamentos do período
    @estimates = Estimate.where(estimate_date: @start_date..@end_date)
    @estimates_approved = @estimates.where(status: 'aprovado')
    @conversion_rate = @estimates_approved.count.to_f / @estimates.count * 100 if @estimates.any?

    # Trabalhos
    @jobs = Job.where(created_at: @start_date..@end_date)
    @jobs_completed = @jobs.where(status: 'concluído')

    # Vendas por mês (últimos 12 meses)
    @monthly_sales = Invoice.where('invoice_date >= ?', 12.months.ago)
                           .group("DATE_TRUNC('month', invoice_date)")
                           .sum(:total_value)
  end

  def inventory
    # Relatório de inventário
    redirect_to reports_inventory_items_path
  end

  def daily_revenues
    # Relatório de receitas diárias do Cyber Café
    @month = params[:month]&.to_i || Date.today.month
    @year = params[:year]&.to_i || Date.today.year

    all_month_revenues = DailyRevenue.for_month(@month, @year)
    @daily_revenues = all_month_revenues.by_date.limit(100)

    @total_entries = all_month_revenues.sum(:entry)
    @total_exits = all_month_revenues.sum(:exit)
    @total_balance = @total_entries - @total_exits
    @entries_count = all_month_revenues.with_entries.count
    @exits_count = all_month_revenues.with_exits.count

    respond_to do |format|
      format.html
      format.pdf do
        # TODO: Implement PDF generation
      end
    end
  end

  def training_courses
    # Relatório de cursos de formação profissional
    @month = params[:month]&.to_i || Date.today.month
    @year = params[:year]&.to_i || Date.today.year

    all_month_courses = TrainingCourse.for_month(@month, @year)
    @training_courses = all_month_courses.by_date.limit(100)

    @total_value = all_month_courses.sum(:total_value)
    @total_paid = all_month_courses.sum(:amount_paid)
    @total_balance = @total_value - @total_paid
    @active_courses = all_month_courses.where(status: 'active').count
    @completed_courses = all_month_courses.where(status: 'completed').count

    respond_to do |format|
      format.html
      format.pdf do
        # TODO: Implement PDF generation
      end
    end
  end

  def contact_sources
    # Relatório de eficácia dos meios de contacto
    @month = params[:month]&.to_i || Date.today.month
    @year = params[:year]&.to_i || Date.today.year
    @start_date = Date.new(@year, @month, 1)
    @end_date = @start_date.end_of_month

    # Oportunidades por fonte de contacto
    @opportunities_by_source = Opportunity.where(created_at: @start_date..@end_date)
                                          .group(:contact_source)
                                          .count

    @opportunities_won_by_source = Opportunity.where(created_at: @start_date..@end_date, stage: :won)
                                              .group(:contact_source)
                                              .count

    @opportunities_value_by_source = Opportunity.where(created_at: @start_date..@end_date)
                                                .group(:contact_source)
                                                .sum(:value)

    @opportunities_won_value_by_source = Opportunity.where(created_at: @start_date..@end_date, stage: :won)
                                                    .group(:contact_source)
                                                    .sum(:value)

    # Leads por fonte de contacto
    @leads_by_source = Lead.where(created_at: @start_date..@end_date)
                           .group(:contact_source)
                           .count

    @leads_converted_by_source = Lead.where(created_at: @start_date..@end_date)
                                     .where.not(converted_to_customer_id: nil)
                                     .group(:contact_source)
                                     .count

    # Totais
    @total_opportunities = @opportunities_by_source.values.sum
    @total_won = @opportunities_won_by_source.values.sum
    @total_value = @opportunities_value_by_source.values.sum || 0
    @total_won_value = @opportunities_won_value_by_source.values.sum || 0
    @total_leads = @leads_by_source.values.sum
    @total_converted = @leads_converted_by_source.values.sum

    respond_to do |format|
      format.html
      format.pdf do
        # TODO: Implement PDF generation
      end
    end
  end

  private

  def check_admin_access
    unless current_user.admin? || current_user.super_admin?
      redirect_to root_path, alert: 'Acesso negado. Apenas administradores podem ver relatórios.'
    end
  end
end
