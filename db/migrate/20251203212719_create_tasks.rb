class CreateTasks < ActiveRecord::Migration[7.1]
  def change
    create_table :tasks do |t|
      t.string :related_type
      t.integer :related_id
      t.string :title, null: false
      t.text :description
      t.date :due_date
      t.string :status, default: 'pendente'
      t.references :assigned_to_user, foreign_key: { to_table: :users }
      t.references :created_by_user, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :tasks, [:related_type, :related_id]
    add_index :tasks, :status
    add_index :tasks, :due_date
  end
end
