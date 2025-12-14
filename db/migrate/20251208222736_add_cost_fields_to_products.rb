class AddCostFieldsToProducts < ActiveRecord::Migration[7.1]
  def change
    add_column :products, :labor_cost, :decimal, precision: 10, scale: 2, default: 0.0
    add_column :products, :material_cost, :decimal, precision: 10, scale: 2, default: 0.0
    add_column :products, :purchase_price, :decimal, precision: 10, scale: 2, default: 0.0
  end
end
