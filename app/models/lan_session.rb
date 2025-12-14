class LanSession < ApplicationRecord
  acts_as_tenant :tenant
  # Associations
  belongs_to :customer, optional: true
  belongs_to :lan_machine
  belongs_to :created_by_user, class_name: 'User', foreign_key: 'created_by_user_id', optional: true
  has_many :invoices, as: :source, dependent: :nullify

  # Validations
  validates :status, presence: true, inclusion: { in: %w[aberta fechada cancelada] }
  validates :billing_type, inclusion: { in: %w[pré-pago pós-pago pacote] }, allow_blank: true
  validates :start_time, presence: true
  validate :machine_must_be_available, on: :create

  # Callbacks
  before_create :mark_machine_as_occupied
  after_update :update_machine_status, if: :saved_change_to_status?

  # Scopes
  scope :active, -> { where(status: 'aberta') }
  scope :today, -> { where('DATE(start_time) = ?', Date.today) }
  scope :this_month, -> { where('EXTRACT(MONTH FROM start_time) = ? AND EXTRACT(YEAR FROM start_time) = ?', Date.today.month, Date.today.year) }
  scope :last_month, -> { where('EXTRACT(MONTH FROM start_time) = ? AND EXTRACT(YEAR FROM start_time) = ?', Date.today.last_month.month, Date.today.last_month.year) }

  def close!
    return if status != 'aberta'

    self.end_time = Time.current
    self.total_minutes = ((end_time - start_time) / 60).to_i
    calculate_total_value
    self.status = 'fechada'
    save!

    lan_machine.update(status: 'livre')
  end

  def elapsed_minutes
    return total_minutes if status == 'fechada'

    ((Time.current - start_time) / 60).to_i
  end

  def elapsed_hours
    (elapsed_minutes / 60.0).round(2)
  end

  def current_value
    return total_value if status == 'fechada'

    (elapsed_minutes / 60.0 * lan_machine.hourly_rate).round(2)
  end

  def formatted_elapsed_time
    minutes = elapsed_minutes
    hours = minutes / 60
    mins = minutes % 60

    "#{hours}h #{mins}min"
  end

  def calculate_total_value
    if billing_type == 'pacote'
      self.total_value = (package_minutes / 60.0 * lan_machine.hourly_rate).round(2)
    else
      self.total_value = (total_minutes / 60.0 * lan_machine.hourly_rate).round(2)
    end
  end

  private

  def machine_must_be_available
    errors.add(:lan_machine, 'não está disponível') unless lan_machine&.available?
  end

  def mark_machine_as_occupied
    lan_machine.update(status: 'ocupado')
  end

  def update_machine_status
    lan_machine.update(status: 'livre') if status.in?(['fechada', 'cancelada'])
  end
end
