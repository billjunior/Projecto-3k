class AddProductIdToInvoiceItems < ActiveRecord::Migration[7.1]
  def change
    add_column :invoice_items, :product_id, :bigint
    add_index :invoice_items, :product_id
  end
end
