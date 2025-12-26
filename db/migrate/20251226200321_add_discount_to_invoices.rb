class AddDiscountToInvoices < ActiveRecord::Migration[7.1]
  def change
    add_column :invoices, :discount_percentage, :decimal, precision: 5, scale: 2, default: 0.0
    add_column :invoices, :discount_amount, :decimal, precision: 10, scale: 2, default: 0.0
    add_column :invoices, :discount_justification, :text
    add_column :invoices, :subtotal_before_discount, :decimal, precision: 10, scale: 2
    add_column :invoices, :below_margin_warned, :boolean, default: false
    add_column :invoices, :below_margin_warned_at, :datetime

    add_index :invoices, :below_margin_warned
    add_index :invoices, [:tenant_id, :below_margin_warned]
  end
end
