class CreateEstimates < ActiveRecord::Migration[7.1]
  def change
    create_table :estimates do |t|
      t.references :customer, null: false, foreign_key: true
      t.string :estimate_number
      t.string :status
      t.date :valid_until
      t.decimal :total_value, precision: 10, scale: 2
      t.references :created_by_user, foreign_key: { to_table: :users }
      t.text :notes

      t.timestamps
    end

    add_index :estimates, :estimate_number, unique: true
    add_index :estimates, :status
  end
end
