class CreateLeads < ActiveRecord::Migration[7.1]
  def change
    create_table :leads do |t|
      t.references :tenant, null: false, foreign_key: true
      t.string :name, null: false
      t.string :email
      t.string :phone
      t.string :company
      t.string :source
      t.integer :classification, default: 1  # 0:hot, 1:warm, 2:cold
      t.references :assigned_to_user, foreign_key: { to_table: :users }
      t.references :converted_to_customer, foreign_key: { to_table: :customers }
      t.datetime :converted_at
      t.text :notes

      t.timestamps
    end

    add_index :leads, :classification
    add_index :leads, :converted_at
  end
end
