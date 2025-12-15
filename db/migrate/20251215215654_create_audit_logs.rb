class CreateAuditLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :audit_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.references :tenant, null: false, foreign_key: true
      t.string :action, null: false
      t.string :auditable_type
      t.integer :auditable_id
      t.text :changed_data
      t.string :ip_address
      t.text :user_agent

      t.timestamps
    end

    add_index :audit_logs, [:auditable_type, :auditable_id]
    add_index :audit_logs, :created_at
    add_index :audit_logs, [:tenant_id, :created_at]
  end
end
