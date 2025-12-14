class Job < ApplicationRecord
  acts_as_tenant :tenant
  # Associations
  belongs_to :customer
  belongs_to :source_estimate, class_name: 'Estimate', foreign_key: 'source_estimate_id', optional: true
  belongs_to :created_by_user, class_name: 'User', foreign_key: 'created_by_user_id', optional: true
  has_many :job_items, dependent: :destroy
  has_many :job_files, dependent: :destroy
  has_many :invoices, as: :source, dependent: :nullify

  # Nested attributes
  accepts_nested_attributes_for :job_items, allow_destroy: true, reject_if: :all_blank

  # Validations
  validates :job_number, presence: true, uniqueness: true
  validates :title, presence: true
  validates :status, presence: true, inclusion: { in: %w[novo em_design em_impressao em_acabamento pronto entregue cancelado] }
  validates :priority, presence: true, inclusion: { in: %w[baixa normal alta urgente] }

  # Callbacks
  before_validation :generate_job_number, on: :create
  before_save :calculate_balance

  # Scopes
  scope :em_producao, -> { where.not(status: ['entregue', 'cancelado']) }
  scope :atrasados, -> { where('delivery_date < ? AND status NOT IN (?)', Date.today, ['entregue', 'cancelado']) }
  scope :by_priority, -> { order(Arel.sql("CASE priority WHEN 'urgente' THEN 0 WHEN 'alta' THEN 1 WHEN 'normal' THEN 2 WHEN 'baixa' THEN 3 END")) }
  scope :recent, -> { order(created_at: :desc) }

  def self.generate_job_number
    "JOB-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(3).upcase}"
  end

  def overdue?
    delivery_date.present? && delivery_date < Date.today && !%w[entregue cancelado].include?(status)
  end

  def status_color
    case status
    when 'novo' then 'primary'
    when 'em_design' then 'info'
    when 'em_impressao' then 'warning'
    when 'em_acabamento' then 'warning'
    when 'pronto' then 'success'
    when 'entregue' then 'secondary'
    when 'cancelado' then 'danger'
    else 'light'
    end
  end

  private

  def generate_job_number
    self.job_number ||= self.class.generate_job_number
  end

  def calculate_balance
    self.balance = (total_value || 0) - (advance_paid || 0)
  end
end
