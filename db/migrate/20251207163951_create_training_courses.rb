class CreateTrainingCourses < ActiveRecord::Migration[7.1]
  def change
    create_table :training_courses do |t|
      t.references :tenant, null: false, foreign_key: true
      t.string :student_name
      t.string :module_name
      t.decimal :total_value
      t.decimal :amount_paid
      t.integer :training_days
      t.date :start_date
      t.date :end_date
      t.integer :payment_type
      t.integer :status
      t.text :notes

      t.timestamps
    end
  end
end
