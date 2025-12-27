class AddVariableCostsToProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :packaging_cost, :decimal, precision: 10, scale: 2, default: 0.0
    add_column :products, :sales_commission_percentage, :decimal, precision: 5, scale: 2, default: 0.0
    add_column :products, :sales_tax_percentage, :decimal, precision: 5, scale: 2, default: 0.0
    add_column :products, :card_fee_percentage, :decimal, precision: 5, scale: 2, default: 0.0
  end
end
