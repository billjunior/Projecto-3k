class CreateJobItems < ActiveRecord::Migration[7.1]
  def change
    create_table :job_items do |t|
      t.references :job, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity
      t.decimal :unit_price
      t.decimal :subtotal

      t.timestamps
    end
  end
end
