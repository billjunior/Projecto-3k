class CreatePricingWarnings < ActiveRecord::Migration[7.1]
  def change
    create_table :pricing_warnings do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :warnable, polymorphic: true, null: false
      t.references :created_by_user, foreign_key: { to_table: :users }

      t.string :warning_type, null: false # 'below_margin', 'high_discount'
      t.decimal :expected_margin, precision: 5, scale: 2
      t.decimal :actual_margin, precision: 5, scale: 2
      t.decimal :margin_deficit, precision: 5, scale: 2
      t.decimal :profit_loss, precision: 10, scale: 2

      t.jsonb :item_breakdown, default: {}
      t.text :justification
      t.boolean :director_notified, default: false
      t.datetime :director_notified_at

      t.timestamps
    end

    add_index :pricing_warnings, :warning_type
    add_index :pricing_warnings, [:tenant_id, :warning_type]
    add_index :pricing_warnings, [:warnable_type, :warnable_id]
  end
end
