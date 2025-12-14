class CreateInvoices < ActiveRecord::Migration[7.1]
  def change
    create_table :invoices do |t|
      t.string :invoice_number
      t.references :customer, null: false, foreign_key: true
      t.string :invoice_type
      t.string :source_type
      t.integer :source_id
      t.decimal :total_value, precision: 10, scale: 2
      t.decimal :paid_value, precision: 10, scale: 2, default: 0
      t.string :status, default: 'pendente'
      t.date :payment_date
      t.string :payment_method
      t.references :created_by_user, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :invoices, :invoice_number, unique: true
    add_index :invoices, :status
    add_index :invoices, [:source_type, :source_id]
  end
end
