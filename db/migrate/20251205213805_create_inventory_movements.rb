class CreateInventoryMovements < ActiveRecord::Migration[7.1]
  def change
    create_table :inventory_movements do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :inventory_item, null: false, foreign_key: true
      t.integer :movement_type
      t.decimal :quantity
      t.date :date
      t.text :notes
      t.references :created_by_user, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
