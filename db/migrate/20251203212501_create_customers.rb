class CreateCustomers < ActiveRecord::Migration[7.1]
  def change
    create_table :customers do |t|
      t.string :name
      t.string :customer_type
      t.string :tax_id
      t.string :phone
      t.string :whatsapp
      t.string :email
      t.text :address
      t.text :notes

      t.timestamps
    end
  end
end
