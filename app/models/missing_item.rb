class MissingItem < ApplicationRecord
  acts_as_tenant :tenant

  # Associations
  belongs_to :tenant
  belongs_to :inventory_item, optional: true
  belongs_to :created_by_user, class_name: 'User', optional: true

  # Enums
  enum source: { manual: 0, automatic: 1 }
  enum urgency_level: { baixa: 0, media: 1, alta: 2, critica: 3 }
  enum status: { pending: 0, ordered: 1, resolved: 2 }

  # Validations
  validates :item_name, presence: true
  validates :urgency_level, presence: true

  # Scopes
  scope :by_urgency, -> { order(urgency_level: :desc, created_at: :desc) }
  scope :needs_notification, -> { where(last_notified_at: nil).or(where('last_notified_at < ?', 24.hours.ago)) }
  scope :for_weekly_report, -> { pending.where(included_in_weekly_report: false) }

  # Callbacks
  after_create :send_immediate_notification

  # Helper Methods
  def urgency_badge_class
    {
      'critica' => 'danger',
      'alta' => 'warning',
      'media' => 'info',
      'baixa' => 'secondary'
    }[urgency_level]
  end

  def urgency_text
    {
      'critica' => 'Crítica',
      'alta' => 'Alta',
      'media' => 'Média',
      'baixa' => 'Baixa'
    }[urgency_level]
  end

  def source_text
    source == 'automatic' ? 'Automático' : 'Manual'
  end

  def status_text
    {
      'pending' => 'Pendente',
      'ordered' => 'Pedido',
      'resolved' => 'Resolvido'
    }[status]
  end

  def status_badge_class
    {
      'pending' => 'warning',
      'ordered' => 'info',
      'resolved' => 'success'
    }[status]
  end

  private

  def send_immediate_notification
    recipients = tenant.company_setting&.missing_items_recipients || []

    recipients.each do |email|
      MissingItemsMailer.immediate_alert(tenant, self, email).deliver_now
    rescue => e
      Rails.logger.error "Failed to send missing item alert: #{e.message}"
    end

    update_column(:last_notified_at, Time.current)
  end
end
