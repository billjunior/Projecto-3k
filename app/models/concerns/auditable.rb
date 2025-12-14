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
    audit_data = {
      action: action,
      model: record.class.name,
      record_id: record.id,
      user_id: current_user_id,
      tenant_id: ActsAsTenant.current_tenant&.id,
      timestamp: Time.current,
      ip_address: current_ip_address
    }.merge(extra_data)

    Rails.logger.info "[AUDIT] #{audit_data.to_json}"
  end

  def current_user_id
    # Try to get current user from various contexts
    if defined?(Current) && Current.respond_to?(:user)
      Current.user&.id
    elsif Thread.current[:current_user_id]
      Thread.current[:current_user_id]
    end
  end

  def current_ip_address
    Thread.current[:current_ip_address] || 'unknown'
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
