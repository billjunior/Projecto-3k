class CreateProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :products do |t|
      t.string :name
      t.string :category
      t.string :unit
      t.decimal :base_price
      t.boolean :active

      t.timestamps
    end
  end
end
