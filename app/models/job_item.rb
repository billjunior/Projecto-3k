class JobItem < ApplicationRecord
  acts_as_tenant :tenant
  belongs_to :job
  belongs_to :product
  
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  before_save :calculate_subtotal
  
  private
  
  def calculate_subtotal
    self.subtotal = quantity * unit_price
  end
end
