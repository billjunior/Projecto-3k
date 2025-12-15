# frozen_string_literal: true

# Auditable concern - Audit logging for models
module Auditable
  extend ActiveSupport::Concern

  included do
    # Callbacks for audit logging
    after_create :log_create
    after_update :log_update
    after_destroy :log_destroy
  end

  private

  def log_create
    log_audit_event('create', self)
  end

  def log_update
    return unless saved_changes?

    changed_attributes = saved_changes.keys.reject { |k| k == 'updated_at' }
    return if changed_attributes.empty?

    log_audit_event('update', self, changed_attributes: changed_attributes)
  end

  def log_destroy
    log_audit_event('destroy', self)
  end

  def log_audit_event(action, record, extra_data = {})
    return unless Current.user # Don't log if no user (e.g. rake tasks)

    begin
      AuditLog.create!(
        user: Current.user,
        tenant: ActsAsTenant.current_tenant,
        action: action,
        auditable_type: record.class.name,
        auditable_id: record.id,
        changed_data: extra_data[:changed_attributes] ? saved_changes.slice(*extra_data[:changed_attributes]) : {},
        ip_address: Current.ip_address,
        user_agent: Current.user_agent
      )
    rescue => e
      Rails.logger.error "[AUDIT] Failed to create audit log: #{e.message}"
    end
  end

  class_methods do
    # Class methods for audit queries
    def audit_trail_for(record_id)
      # This would query an audit log table if you have one
      # For now, this is a placeholder
      Rails.logger.info "Fetching audit trail for #{name} ##{record_id}"
    end
  end
end
