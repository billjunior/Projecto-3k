class CreateServices < ActiveRecord::Migration[7.1]
  def change
    create_table :services do |t|
      t.string :category, null: false
      t.string :name, null: false
      t.text :description
      t.string :estimated_time
      t.string :availability
      t.boolean :active, default: true, null: false
      t.references :tenant, null: false, foreign_key: true

      t.timestamps
    end

    add_index :services, [:tenant_id, :category]
  end
end
