class CreateInventoryItems < ActiveRecord::Migration[7.1]
  def change
    create_table :inventory_items do |t|
      t.references :tenant, null: false, foreign_key: true
      t.string :product_name
      t.string :supplier_phone
      t.decimal :gross_quantity
      t.decimal :net_quantity
      t.decimal :purchase_price
      t.integer :minimum_stock
      t.text :notes

      t.timestamps
    end
  end
end
