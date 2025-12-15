class AuditLogsController < ApplicationController
  before_action :require_admin

  def index
    @audit_logs = AuditLog.includes(:user, :auditable)
                          .recent
                          .page(params[:page])
                          .per(50)

    # Filters
    @audit_logs = @audit_logs.for_user(params[:user_id]) if params[:user_id].present?
    @audit_logs = @audit_logs.for_model(params[:model_type]) if params[:model_type].present?
    @audit_logs = @audit_logs.for_action(params[:action_filter]) if params[:action_filter].present?

    # Date range
    if params[:start_date].present?
      @audit_logs = @audit_logs.where('created_at >= ?', Date.parse(params[:start_date]))
    end
    if params[:end_date].present?
      @audit_logs = @audit_logs.where('created_at <= ?', Date.parse(params[:end_date]).end_of_day)
    end
  end

  def show
    @audit_log = AuditLog.find(params[:id])
  end

  private

  def require_admin
    unless current_user.super_admin? || current_user.admin?
      redirect_to root_path, alert: 'Apenas administradores podem acessar os logs de auditoria.'
    end
  end
end
