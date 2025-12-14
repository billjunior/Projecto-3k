class DailyRevenuesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_daily_revenue, only: [:edit, :update, :destroy]

  def index
    # Pundit: Use policy_scope for index action
    @month = params[:month]&.to_i || Date.today.month
    @year = params[:year]&.to_i || Date.today.year

    @daily_revenues = policy_scope(DailyRevenue).for_month(@month, @year).by_date.page(params[:page]).per(20)

    # Calculate monthly totals
    all_month_revenues = policy_scope(DailyRevenue).for_month(@month, @year)
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

  def new
    @daily_revenue = DailyRevenue.new(date: Date.today)
    # Pundit: Authorize new action (checks create?)
    authorize @daily_revenue
  end

  def create
    @daily_revenue = DailyRevenue.new(daily_revenue_params)
    # Pundit: Authorize create action
    authorize @daily_revenue

    if @daily_revenue.save
      redirect_to daily_revenues_path(month: @daily_revenue.date.month, year: @daily_revenue.date.year),
                  notice: 'Receita registada com sucesso.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # Pundit: Authorize edit action (checks update?)
    authorize @daily_revenue
  end

  def update
    # Pundit: Authorize update action
    authorize @daily_revenue

    if @daily_revenue.update(daily_revenue_params)
      redirect_to daily_revenues_path(month: @daily_revenue.date.month, year: @daily_revenue.date.year),
                  notice: 'Receita actualizada com sucesso.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # Pundit: Authorize destroy action
    authorize @daily_revenue

    month = @daily_revenue.date.month
    year = @daily_revenue.date.year
    @daily_revenue.destroy
    redirect_to daily_revenues_path(month: month, year: year),
                notice: 'Receita eliminada com sucesso.'
  end

  private

  def set_daily_revenue
    @daily_revenue = DailyRevenue.find(params[:id])
  end

  def daily_revenue_params
    params.require(:daily_revenue).permit(
      :date, :description, :quantity, :unit_price,
      :entry, :exit, :payment_type, :notes
    )
  end
end
