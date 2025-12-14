class CreateOpportunities < ActiveRecord::Migration[7.1]
  def change
    create_table :opportunities do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true
      t.references :lead, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.decimal :value, precision: 10, scale: 2
      t.integer :probability, default: 50
      t.integer :stage, default: 0, null: false  # 0:new, 1:qualified, 2:proposal, 3:negotiation, 4:won, 5:lost
      t.date :expected_close_date
      t.date :actual_close_date
      t.text :won_lost_reason
      t.references :assigned_to_user, foreign_key: { to_table: :users }
      t.references :created_by_user, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :opportunities, :stage
    add_index :opportunities, :expected_close_date
  end
end
