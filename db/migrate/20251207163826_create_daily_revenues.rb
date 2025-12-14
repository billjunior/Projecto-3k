class CreateDailyRevenues < ActiveRecord::Migration[7.1]
  def change
    create_table :daily_revenues do |t|
      t.references :tenant, null: false, foreign_key: true
      t.date :date
      t.string :description
      t.integer :quantity
      t.decimal :unit_price
      t.decimal :entry
      t.decimal :exit
      t.decimal :total
      t.integer :payment_type
      t.text :notes

      t.timestamps
    end
  end
end
