class AuditLog < ApplicationRecord
  acts_as_tenant :tenant

  belongs_to :user
  belongs_to :tenant
  belongs_to :auditable, polymorphic: true, optional: true

  # Serialization
  serialize :changed_data, coder: JSON

  # Validations
  validates :action, presence: true
  validates :user_id, presence: true
  validates :tenant_id, presence: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :for_user, ->(user_id) { where(user_id: user_id) }
  scope :for_model, ->(model_type) { where(auditable_type: model_type) }
  scope :for_record, ->(model_type, record_id) { where(auditable_type: model_type, auditable_id: record_id) }
  scope :for_action, ->(action) { where(action: action) }
  scope :today, -> { where('created_at >= ?', Date.today.beginning_of_day) }
  scope :this_week, -> { where('created_at >= ?', 1.week.ago) }
  scope :this_month, -> { where('created_at >= ?', 1.month.ago) }

  # Helper methods
  def action_description
    case action
    when 'create'
      'criou'
    when 'update'
      'atualizou'
    when 'destroy'
      'excluiu'
    else
      action
    end
  end

  def auditable_description
    if auditable
      "#{auditable_type} ##{auditable_id}"
    else
      "#{auditable_type} ##{auditable_id} (excluído)"
    end
  end

  def formatted_changes
    return {} unless changed_data.is_a?(Hash)

    changed_data.transform_values do |value|
      if value.is_a?(Array) && value.length == 2
        { from: value[0], to: value[1] }
      else
        value
      end
    end
  end
end
