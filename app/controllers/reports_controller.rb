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
    ).includes(:lan_machine, :customer).order(start_time: :desc).page(params[:page]).per(20)

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
                              .page(params[:page]).per(20)

    @total_invoiced = invoices_scope.sum(:total_value)
    @total_paid = invoices_scope.joins(:payments).sum('payments.amount')
    @pending_amount = @total_invoiced - @total_paid
    @invoices_by_status = invoices_scope.group(:status).count

    respond_to do |format|
      format.html
      format.pdf do
        pdf = InvoicesReportPdf.new(ActsAsTenant.current_tenant, @start_date, @end_date).generate
        send_data pdf, filename: "relatorio_faturas_#{@start_date.strftime('%Y%m%d')}_#{@end_date.strftime('%Y%m%d')}.pdf",
                       type: 'application/pdf',
                       disposition: 'inline'
      end
    end
  end

  def customers
    # Relatório de clientes
    # Performance fix: Properly eager load all associations needed in views
    customers_base = Customer.includes(
      invoices: [:created_by_user, :payments],
      opportunities: [:assigned_to_user, :created_by_user],
      estimates: [:created_by_user, estimate_items: :product]
    )

    # Filtros
    if params[:customer_type].present?
      customers_base = customers_base.where(customer_type: params[:customer_type])
    end

    if params[:start_date].present? && params[:end_date].present?
      start_date = Date.parse(params[:start_date])
      end_date = Date.parse(params[:end_date])
      customers_base = customers_base.where(created_at: start_date..end_date)
    end

    @customers = customers_base.order(created_at: :desc).page(params[:page]).per(20)

    # Performance fix: Use single queries for stats
    @total_customers = Customer.count
    @customers_with_invoices = Customer.joins(:invoices).distinct.count

    # Performance fix: Use separate query for top customers with proper aggregation
    @top_customers = Customer
                       .select('customers.id, customers.name, COALESCE(SUM(invoices.total_value), 0) as total_spent')
                       .left_joins(:invoices)
                       .group('customers.id, customers.name')
                       .order('total_spent DESC')
                       .limit(10)

    # Chart data for visualizations
    @customers_by_type = Customer.group(:customer_type).count
    # Temporary workaround using raw SQL until server is restarted
    @customer_acquisition_data = Customer
      .where('created_at >= ?', 12.months.ago)
      .group("DATE_TRUNC('month', created_at)")
      .count
      .transform_keys { |date| date.strftime('%b %Y') }

    respond_to do |format|
      format.html
      format.pdf do
        all_customers = Customer.includes(
          invoices: [:created_by_user, :payments],
          opportunities: [:assigned_to_user, :created_by_user],
          estimates: [:created_by_user, estimate_items: :product]
        ).order(created_at: :desc)
        pdf = CustomersReportPdf.new(ActsAsTenant.current_tenant, all_customers).generate
        send_data pdf, filename: "relatorio_clientes_#{Time.current.strftime('%Y%m%d')}.pdf",
                       type: 'application/pdf',
                       disposition: 'inline'
      end
      format.csv do
        csv_data = generate_customers_csv(customers_base.order(created_at: :desc))
        send_data csv_data, filename: "relatorio_clientes_#{Time.current.strftime('%Y%m%d')}.csv",
                           type: 'text/csv',
                           disposition: 'attachment'
      end
    end
  end

  def opportunities
    # Relatório de oportunidades (pipeline CRM)
    # Base query for filtering
    opportunities_scope = Opportunity.all

    @opportunities = opportunities_scope.includes(:customer, :assigned_to_user)
                                        .order(created_at: :desc)
                                        .page(params[:page]).per(20)

    @opportunities_by_stage = opportunities_scope.group(:stage).count
    @total_value = opportunities_scope.sum(:value)
    # Performance fix: Calculate weighted_value in SQL instead of Ruby
    @weighted_value = opportunities_scope.sum('COALESCE(value, 0) * COALESCE(probability, 0) / 100.0') || 0
    @conversion_rate = opportunities_scope.won.count.to_f / opportunities_scope.count * 100 if opportunities_scope.any?
    @avg_deal_size = opportunities_scope.won.average(:value)

    # Chart data for visualizations
    @pipeline_funnel_data = {
      'Novo' => @opportunities_by_stage[0] || 0,
      'Qualificado' => @opportunities_by_stage[1] || 0,
      'Proposta' => @opportunities_by_stage[2] || 0,
      'Negociação' => @opportunities_by_stage[3] || 0
    }
    @win_loss_data = {
      'Ganhos' => @opportunities_by_stage[4] || 0,
      'Perdidos' => @opportunities_by_stage[5] || 0
    }
    # Temporary workaround using raw SQL until server is restarted
    @monthly_opportunities_data = opportunities_scope
      .where('created_at >= ?', 12.months.ago)
      .group("DATE_TRUNC('month', created_at)")
      .count
      .transform_keys { |date| date.strftime('%b %Y') }
    @monthly_won_value_data = opportunities_scope.won
      .where('created_at >= ?', 12.months.ago)
      .group("DATE_TRUNC('month', created_at)")
      .sum(:value)
      .transform_keys { |date| date.strftime('%b %Y') }

    respond_to do |format|
      format.html
      format.pdf do
        all_opportunities = Opportunity.includes(:customer, :assigned_to_user).order(created_at: :desc)
        pdf = OpportunitiesReportPdf.new(ActsAsTenant.current_tenant, all_opportunities).generate
        send_data pdf, filename: "relatorio_oportunidades_#{Time.current.strftime('%Y%m%d')}.pdf",
                       type: 'application/pdf',
                       disposition: 'inline'
      end
      format.csv do
        csv_data = generate_opportunities_csv(opportunities_scope.includes(:customer, :assigned_to_user))
        send_data csv_data, filename: "relatorio_oportunidades_#{Time.current.strftime('%Y%m%d')}.csv",
                           type: 'text/csv',
                           disposition: 'attachment'
      end
    end
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
    @estimates = Estimate.where(created_at: @start_date..@end_date)
    @estimates_approved = @estimates.where(status: 'aprovado')
    @conversion_rate = @estimates_approved.count.to_f / @estimates.count * 100 if @estimates.any?

    # Trabalhos
    @jobs = Job.where(created_at: @start_date..@end_date)
    @jobs_completed = @jobs.where(status: 'concluído')

    # Chart data for visualizations
    # Temporary workaround using raw SQL until server is restarted
    @monthly_sales = Invoice
      .where('invoice_date >= ?', 12.months.ago)
      .group("DATE_TRUNC('month', invoice_date)")
      .sum(:total_value)
    @monthly_sales_data = @monthly_sales.transform_keys { |date| date.strftime('%b %Y') }
    @top_customers_data = Customer.select('customers.name, COALESCE(SUM(invoices.total_value), 0) as total')
                                   .left_joins(:invoices)
                                   .group('customers.id, customers.name')
                                   .order(Arel.sql('COALESCE(SUM(invoices.total_value), 0) DESC'))
                                   .limit(10)
                                   .pluck(Arel.sql('customers.name'), Arel.sql('COALESCE(SUM(invoices.total_value), 0)'))
                                   .to_h
    @customer_type_data = Customer.group(:customer_type).count

    respond_to do |format|
      format.html
      format.pdf do
        pdf = SalesReportPdf.new(ActsAsTenant.current_tenant, @start_date, @end_date).generate
        send_data pdf, filename: "relatorio_vendas_#{@start_date.strftime('%Y%m%d')}_#{@end_date.strftime('%Y%m%d')}.pdf",
                       type: 'application/pdf',
                       disposition: 'inline'
      end
      format.csv do
        csv_data = generate_sales_csv(@invoices.includes(:customer, :created_by_user).order(invoice_date: :desc))
        send_data csv_data, filename: "relatorio_vendas_#{@start_date.strftime('%Y%m%d')}_#{@end_date.strftime('%Y%m%d')}.csv",
                           type: 'text/csv',
                           disposition: 'attachment'
      end
    end
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
    @daily_revenues = all_month_revenues.by_date.page(params[:page]).per(20)

    @total_entries = all_month_revenues.sum(:entry)
    @total_exits = all_month_revenues.sum(:exit)
    @total_balance = @total_entries - @total_exits
    @entries_count = all_month_revenues.with_entries.count
    @exits_count = all_month_revenues.with_exits.count

    respond_to do |format|
      format.html
      format.pdf do
        pdf = DailyRevenueReportPdf.new(ActsAsTenant.current_tenant, @month, @year).generate
        send_data pdf, filename: "receitas_diarias_#{@month}_#{@year}.pdf",
                       type: 'application/pdf',
                       disposition: 'inline'
      end
    end
  end

  def training_courses
    # Relatório de cursos de formação profissional
    @month = params[:month]&.to_i || Date.today.month
    @year = params[:year]&.to_i || Date.today.year

    all_month_courses = TrainingCourse.for_month(@month, @year)
    @training_courses = all_month_courses.by_date.page(params[:page]).per(20)

    @total_value = all_month_courses.sum(:total_value)
    @total_paid = all_month_courses.sum(:amount_paid)
    @total_balance = @total_value - @total_paid
    @active_courses = all_month_courses.where(status: 'active').count
    @completed_courses = all_month_courses.where(status: 'completed').count

    respond_to do |format|
      format.html
      format.pdf do
        pdf = TrainingCoursesReportPdf.new(ActsAsTenant.current_tenant, @month, @year).generate
        send_data pdf, filename: "relatorio_formacoes_#{@month}_#{@year}.pdf",
                       type: 'application/pdf',
                       disposition: 'inline'
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
        report_data = {
          opportunities_by_source: @opportunities_by_source,
          opportunities_won_by_source: @opportunities_won_by_source,
          opportunities_value_by_source: @opportunities_value_by_source,
          opportunities_won_value_by_source: @opportunities_won_value_by_source,
          leads_by_source: @leads_by_source,
          leads_converted_by_source: @leads_converted_by_source,
          total_opportunities: @total_opportunities,
          total_won: @total_won,
          total_value: @total_value,
          total_won_value: @total_won_value,
          total_leads: @total_leads,
          total_converted: @total_converted
        }
        pdf = ContactSourcesReportPdf.new(ActsAsTenant.current_tenant, @month, @year, report_data).generate
        send_data pdf, filename: "relatorio_fontes_contacto_#{@month}_#{@year}.pdf",
                       type: 'application/pdf',
                       disposition: 'inline'
      end
    end
  end

  private

  def check_admin_access
    unless current_user.admin? || current_user.super_admin?
      redirect_to root_path, alert: 'Acesso negado. Apenas administradores podem ver relatórios.'
    end
  end

  # CSV generation methods
  def generate_opportunities_csv(opportunities)
    require 'csv'

    CSV.generate(headers: true) do |csv|
      csv << ['Título', 'Cliente', 'Etapa', 'Valor', 'Probabilidade', 'Valor Ponderado', 'Responsável', 'Data Criação']

      opportunities.each do |opp|
        csv << [
          opp.title,
          opp.customer.name,
          opp.stage_display_name,
          opp.value || 0,
          "#{opp.probability}%",
          opp.weighted_value,
          opp.assigned_to_user&.name || 'Não atribuído',
          opp.created_at.strftime('%d/%m/%Y')
        ]
      end
    end
  end

  def generate_customers_csv(customers)
    require 'csv'

    CSV.generate(headers: true) do |csv|
      csv << ['Nome', 'Tipo', 'NIF', 'Email', 'Telefone', 'Data Criação']

      customers.each do |customer|
        csv << [
          customer.name,
          customer.customer_type_label,
          customer.tax_id,
          customer.email,
          customer.phone,
          customer.created_at.strftime('%d/%m/%Y')
        ]
      end
    end
  end

  def generate_sales_csv(invoices)
    require 'csv'

    CSV.generate(headers: true) do |csv|
      csv << ['Número', 'Cliente', 'Data', 'Valor Total', 'Estado', 'Criado Por']

      invoices.each do |invoice|
        csv << [
          invoice.invoice_number,
          invoice.customer.name,
          invoice.invoice_date.strftime('%d/%m/%Y'),
          invoice.total_value,
          invoice.status,
          invoice.created_by_user.name
        ]
      end
    end
  end
end
