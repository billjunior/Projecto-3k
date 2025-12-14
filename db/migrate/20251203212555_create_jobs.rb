class CreateJobs < ActiveRecord::Migration[7.1]
  def change
    create_table :jobs do |t|
      t.string :job_number
      t.references :customer, null: false, foreign_key: true
      t.references :source_estimate, foreign_key: { to_table: :estimates }
      t.string :title, null: false
      t.text :description
      t.string :status, default: 'novo'
      t.string :priority, default: 'normal'
      t.date :delivery_date
      t.decimal :total_value, precision: 10, scale: 2
      t.decimal :advance_paid, precision: 10, scale: 2, default: 0
      t.decimal :balance, precision: 10, scale: 2
      t.references :created_by_user, foreign_key: { to_table: :users }
      t.text :production_notes

      t.timestamps
    end

    add_index :jobs, :job_number, unique: true
    add_index :jobs, :status
    add_index :jobs, :priority
    add_index :jobs, :delivery_date
  end
end
