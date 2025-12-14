class PriceRule < ApplicationRecord
  acts_as_tenant :tenant
  belongs_to :product
  
  validates :min_qty, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :unit_price, presence: true, numericality: { greater_than: 0 }
  validate :max_qty_must_be_greater_than_min
  
  private
  
  def max_qty_must_be_greater_than_min
    return if max_qty.nil?
    errors.add(:max_qty, 'deve ser maior que quantidade mínima') if max_qty < min_qty
  end
end
