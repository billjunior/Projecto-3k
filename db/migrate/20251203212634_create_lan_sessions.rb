class CreateLanSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :lan_sessions do |t|
      t.references :customer, foreign_key: true
      t.references :lan_machine, null: false, foreign_key: true
      t.datetime :start_time
      t.datetime :end_time
      t.string :status, default: 'aberta'
      t.string :billing_type
      t.integer :package_minutes
      t.integer :total_minutes
      t.decimal :total_value, precision: 10, scale: 2
      t.references :created_by_user, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :lan_sessions, :status
    add_index :lan_sessions, :start_time
  end
end
