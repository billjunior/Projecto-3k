class DashboardController < ApplicationController
  def index
    @customers_count = Customer.count
    @products_count = Product.count
    @active_jobs = Job.where.not(status: :completed).count
    @pending_invoices = Invoice.where(status: :pending).count
    @today_revenue = calculate_today_revenue

    # Recent activities
    @recent_jobs = Job.order(created_at: :desc).limit(5)
    @pending_tasks = Task.where(status: 'pendente').order(due_date: :asc).limit(5)
  end

  private

  def calculate_today_revenue
    today_payments = Payment.where('created_at >= ?', Date.today.beginning_of_day).sum(:amount)
    today_sessions = LanSession.where('end_time >= ? AND end_time IS NOT NULL', Date.today.beginning_of_day).sum(:total_value)
    today_payments + today_sessions
  end
end
