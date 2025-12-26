class DashboardController < ApplicationController
  def index
    @customers_count = Customer.count
    @products_count = Product.count
    @active_jobs = Job.where.not(status: :completed).count
    @pending_invoices = Invoice.where(status: :pending).count
    @today_revenue = calculate_today_revenue

    # CRM Metrics
    @leads_count = Lead.not_converted.count
    @hot_leads_count = Lead.not_converted.hot.count
    @opportunities_count = Opportunity.open.count
    @opportunities_value = Opportunity.open.sum(:value) || 0
    @opportunities_weighted_value = Opportunity.open.sum('COALESCE(value, 0) * COALESCE(probability, 0) / 100.0') || 0

    # Conversion Rates
    total_leads = Lead.count
    converted_leads = Lead.converted.count
    @lead_conversion_rate = total_leads > 0 ? (converted_leads.to_f / total_leads * 100).round(1) : 0

    total_opportunities = Opportunity.count
    won_opportunities = Opportunity.won.count
    @opportunity_win_rate = total_opportunities > 0 ? (won_opportunities.to_f / total_opportunities * 100).round(1) : 0

    # Chart data
    # Temporary workaround using raw SQL until server is restarted
    @monthly_sales_data = Payment
      .where('created_at >= ?', 6.months.ago)
      .group("DATE_TRUNC('month', created_at)")
      .sum(:amount)
      .transform_keys { |date| date.strftime('%b %Y') }

    @opportunities_by_stage = Opportunity.group(:stage).count
    @leads_by_source = Lead.group(:contact_source).count

    # Recent activities
    @recent_jobs = Job.order(created_at: :desc).limit(5)
    @pending_tasks = Task.where(status: 'pendente').order(due_date: :asc).limit(5)
    @recent_communications = Communication.includes(:created_by_user, :communicable).recent.limit(5)
  end

  private

  def calculate_today_revenue
    today_payments = Payment.where('created_at >= ?', Date.today.beginning_of_day).sum(:amount)
    today_sessions = LanSession.where('end_time >= ? AND end_time IS NOT NULL', Date.today.beginning_of_day).sum(:total_value)
    today_payments + today_sessions
  end
end
