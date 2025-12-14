class AddDateFieldsToInvoices < ActiveRecord::Migration[7.1]
  def change
    add_column :invoices, :invoice_date, :date
    add_column :invoices, :due_date, :date
  end
end
