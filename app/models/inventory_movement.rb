class InventoryMovement < ApplicationRecord
  acts_as_tenant :tenant

  # Associations
  belongs_to :inventory_item
  belongs_to :created_by_user, class_name: 'User', foreign_key: 'created_by_user_id', optional: true

  # Enums
  enum movement_type: { entry: 0, exit: 1 }

  # Validations
  validates :movement_type, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :date, presence: true
  validate :sufficient_stock_for_exit, if: :exit?

  # Callbacks
  after_create :update_inventory_quantities
  after_destroy :revert_inventory_quantities

  # Scopes
  # Note: .entry and .exit scopes are automatically created by the enum
  scope :this_month, -> { where('EXTRACT(MONTH FROM date) = ? AND EXTRACT(YEAR FROM date) = ?', Date.today.month, Date.today.year) }
  scope :by_month, ->(month, year) { where('EXTRACT(MONTH FROM date) = ? AND EXTRACT(YEAR FROM date) = ?', month, year) }

  private

  def sufficient_stock_for_exit
    if exit? && inventory_item && quantity > inventory_item.net_quantity
      errors.add(:quantity, "não pode ser maior que o stock disponível (#{inventory_item.net_quantity})")
    end
  end

  def update_inventory_quantities
    if entry?
      inventory_item.increment!(:net_quantity, quantity)
    elsif exit?
      inventory_item.decrement!(:net_quantity, quantity)
    end
  end

  def revert_inventory_quantities
    if entry?
      inventory_item.decrement!(:net_quantity, quantity)
    elsif exit?
      inventory_item.increment!(:net_quantity, quantity)
    end
  end
end
