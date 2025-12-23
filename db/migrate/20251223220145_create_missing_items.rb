class CreateMissingItems < ActiveRecord::Migration[7.1]
  def change
    create_table :missing_items do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :inventory_item, null: true, foreign_key: true

      # Item details (for manual entries without inventory_item)
      t.string :item_name, null: false
      t.text :description

      # Source tracking
      t.integer :source, default: 0  # 0: manual, 1: automatic

      # Urgency level
      t.integer :urgency_level, default: 1  # 0: baixa, 1: media, 2: alta, 3: critica

      # Status
      t.integer :status, default: 0  # 0: pending, 1: ordered, 2: resolved

      # Notification tracking
      t.datetime :last_notified_at
      t.boolean :included_in_weekly_report, default: false

      # Audit
      t.references :created_by_user, foreign_key: { to_table: :users }, null: true

      t.timestamps
    end

    add_index :missing_items, [:tenant_id, :status]
    add_index :missing_items, [:tenant_id, :urgency_level]
  end
end
