class InventoryItem < ApplicationRecord
  acts_as_tenant :tenant

  # Associations
  has_many :inventory_movements, dependent: :destroy

  # Validations
  validates :product_name, presence: true
  validates :supplier_phone, presence: true
  validates :gross_quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :net_quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :purchase_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :minimum_stock, presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }

  # Scopes
  scope :low_stock, -> { where('net_quantity <= minimum_stock') }
  scope :in_stock, -> { where('net_quantity > 0') }
  scope :out_of_stock, -> { where('net_quantity = 0') }

  # Instance methods
  def low_stock?
    net_quantity <= minimum_stock
  end

  def stock_status
    if net_quantity == 0
      'out_of_stock'
    elsif low_stock?
      'low_stock'
    else
      'in_stock'
    end
  end

  def stock_status_badge_class
    case stock_status
    when 'out_of_stock'
      'danger'
    when 'low_stock'
      'warning'
    else
      'success'
    end
  end

  def stock_status_text
    case stock_status
    when 'out_of_stock'
      'Esgotado'
    when 'low_stock'
      'Stock Baixo'
    else
      'Em Stock'
    end
  end

  def total_entries
    inventory_movements.where(movement_type: 'entry').sum(:quantity)
  end

  def total_exits
    inventory_movements.where(movement_type: 'exit').sum(:quantity)
  end
end
