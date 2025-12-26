class AddDiscountToEstimates < ActiveRecord::Migration[7.1]
  def change
    add_column :estimates, :discount_percentage, :decimal, precision: 5, scale: 2, default: 0.0
    add_column :estimates, :discount_amount, :decimal, precision: 10, scale: 2, default: 0.0
    add_column :estimates, :discount_justification, :text
    add_column :estimates, :subtotal_before_discount, :decimal, precision: 10, scale: 2
    add_column :estimates, :below_margin_warned, :boolean, default: false
    add_column :estimates, :below_margin_warned_at, :datetime

    add_index :estimates, :below_margin_warned
    add_index :estimates, [:tenant_id, :below_margin_warned]
  end
end
