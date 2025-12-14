class CreateEstimateItems < ActiveRecord::Migration[7.1]
  def change
    create_table :estimate_items do |t|
      t.references :estimate, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.string :description
      t.integer :quantity
      t.decimal :unit_price
      t.decimal :subtotal

      t.timestamps
    end
  end
end
