class CreatePriceRules < ActiveRecord::Migration[7.1]
  def change
    create_table :price_rules do |t|
      t.references :product, null: false, foreign_key: true
      t.integer :min_qty
      t.integer :max_qty
      t.decimal :unit_price

      t.timestamps
    end
  end
end
