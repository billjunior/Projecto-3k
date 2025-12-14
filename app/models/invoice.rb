class Invoice < ApplicationRecord
  acts_as_tenant :tenant
  belongs_to :customer
  belongs_to :created_by_user, class_name: 'User', foreign_key: 'created_by_user_id', optional: true
  belongs_to :source, polymorphic: true, optional: true
  has_many :invoice_items, dependent: :destroy
  has_many :payments, dependent: :destroy

  accepts_nested_attributes_for :invoice_items, allow_destroy: true, reject_if: :all_blank

  validates :invoice_number, presence: true, uniqueness: true
  validates :invoice_type, presence: true, inclusion: { in: %w[proforma fatura recibo nota_credito] }
  validates :status, presence: true, inclusion: { in: %w[pago parcial pendente] }

  before_validation :generate_invoice_number, on: :create
  before_save :calculate_paid_value, :update_status

  scope :pending, -> { where(status: 'pendente') }
  scope :paid, -> { where(status: 'pago') }
  scope :recent, -> { order(created_at: :desc) }

  def balance
    total_value - paid_value
  end

  private

  def generate_invoice_number
    self.invoice_number ||= "INV-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(3).upcase}"
  end

  def calculate_paid_value
    self.paid_value = payments.sum(:amount)
  end

  def update_status
    if paid_value >= total_value
      self.status = 'pago'
    elsif paid_value > 0
      self.status = 'parcial'
    else
      self.status = 'pendente'
    end
  end
end
