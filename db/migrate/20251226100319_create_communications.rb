class CreateCommunications < ActiveRecord::Migration[7.1]
  def change
    create_table :communications do |t|
      t.references :communicable, polymorphic: true, null: false
      t.references :tenant, null: false, foreign_key: true
      t.integer :communication_type, null: false
      t.string :subject
      t.text :content
      t.references :created_by_user, null: false, foreign_key: { to_table: :users }
      t.datetime :completed_at

      t.timestamps
    end

    # Indexes for performance
    add_index :communications, [:tenant_id, :communicable_type, :communicable_id],
              name: 'index_communications_on_tenant_and_communicable'
    add_index :communications, [:tenant_id, :communication_type],
              name: 'index_communications_on_tenant_and_type'
    add_index :communications, [:tenant_id, :created_at],
              name: 'index_communications_on_tenant_and_created_at'
  end
end
