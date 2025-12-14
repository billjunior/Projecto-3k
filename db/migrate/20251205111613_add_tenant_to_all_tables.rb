class AddTenantToAllTables < ActiveRecord::Migration[7.1]
  def change
    # List of all tables that need tenant_id
    tables = [
      :users, :customers, :products, :estimates, :estimate_items,
      :jobs, :job_items, :job_files, :invoices, :invoice_items,
      :payments, :tasks, :lan_machines, :lan_sessions, :price_rules
    ]

    tables.each do |table|
      # Add tenant_id as nullable first
      add_reference table, :tenant, null: true, foreign_key: true, index: true
    end
  end
end
