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
  after_create :check_low_stock_and_create_missing_item
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

  def check_low_stock_and_create_missing_item
    return unless exit? # Only check on exits

    if inventory_item.low_stock? && !recent_missing_item_exists?
      MissingItem.create!(
        tenant: inventory_item.tenant,
        inventory_item: inventory_item,
        item_name: inventory_item.product_name,
        description: "Stock baixo detectado automaticamente. Stock atual: #{inventory_item.net_quantity}, Mínimo: #{inventory_item.minimum_stock}",
        source: :automatic,
        urgency_level: determine_urgency_level,
        status: :pending
      )
    end
  end

  def recent_missing_item_exists?
    MissingItem.where(
      inventory_item: inventory_item,
      created_at: 24.hours.ago..Time.current
    ).exists?
  end

  def determine_urgency_level
    return :critica if inventory_item.net_quantity.zero?

    percentage = (inventory_item.net_quantity.to_f / inventory_item.minimum_stock) * 100

    if percentage <= 25
      :alta # Less than 25% of minimum
    elsif percentage <= 50
      :media # Between 25-50% of minimum
    else
      :baixa # Between 50-100% of minimum
    end
  end
end
