class Payment < ApplicationRecord
  acts_as_tenant :tenant
  belongs_to :invoice
  belongs_to :received_by_user, class_name: 'User', foreign_key: 'received_by_user_id', optional: true
  
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :payment_method, presence: true
  validates :payment_date, presence: true
  
  after_save :update_invoice_paid_value
  after_destroy :update_invoice_paid_value
  
  private
  
  def update_invoice_paid_value
    invoice.save
  end
end
