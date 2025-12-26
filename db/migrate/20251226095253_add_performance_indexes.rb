class AddPerformanceIndexes < ActiveRecord::Migration[7.1]
  def change
    # Opportunities indexes for common queries
    add_index :opportunities, [:tenant_id, :stage], name: 'index_opportunities_on_tenant_and_stage'
    add_index :opportunities, [:tenant_id, :assigned_to_user_id], name: 'index_opportunities_on_tenant_and_assigned_user'

    # Invoices indexes for status filtering and reporting
    add_index :invoices, [:tenant_id, :status], name: 'index_invoices_on_tenant_and_status'

    # Payments indexes for invoice payment calculations
    add_index :payments, [:invoice_id, :payment_date], name: 'index_payments_on_invoice_and_date'

    # Estimates indexes for status filtering
    add_index :estimates, [:tenant_id, :status], name: 'index_estimates_on_tenant_and_status'

    # Jobs indexes for status filtering
    add_index :jobs, [:tenant_id, :status], name: 'index_jobs_on_tenant_and_status'

    # Customers indexes for type filtering
    add_index :customers, [:tenant_id, :customer_type], name: 'index_customers_on_tenant_and_type'

    # Leads indexes for classification filtering
    add_index :leads, [:tenant_id, :classification], name: 'index_leads_on_tenant_and_classification'
  end
end
