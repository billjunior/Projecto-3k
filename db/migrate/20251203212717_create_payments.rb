class CreatePayments < ActiveRecord::Migration[7.1]
  def change
    create_table :payments do |t|
      t.references :invoice, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2
      t.string :payment_method
      t.date :payment_date
      t.references :received_by_user, foreign_key: { to_table: :users }
      t.text :notes

      t.timestamps
    end

    add_index :payments, :payment_date
  end
end
