class CreateTenants < ActiveRecord::Migration[7.1]
  def change
    create_table :tenants do |t|
      t.string :name, null: false
      t.string :subdomain, null: false
      t.integer :status, default: 0, null: false
      t.date :subscription_start
      t.date :subscription_end
      t.jsonb :settings, default: {}

      t.timestamps
    end

    add_index :tenants, :subdomain, unique: true
    add_index :tenants, :status
  end
end
