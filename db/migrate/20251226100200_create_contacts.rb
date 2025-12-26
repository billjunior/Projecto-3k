class CreateContacts < ActiveRecord::Migration[7.1]
  def change
    create_table :contacts do |t|
      t.references :contactable, polymorphic: true, null: false
      t.references :tenant, null: false, foreign_key: true
      t.string :name, null: false
      t.string :email
      t.string :phone
      t.string :whatsapp
      t.string :position
      t.string :department
      t.boolean :primary, default: false, null: false
      t.text :notes

      t.timestamps
    end

    # Indexes for performance
    add_index :contacts, [:tenant_id, :contactable_type, :contactable_id],
              name: 'index_contacts_on_tenant_and_contactable'
    add_index :contacts, [:tenant_id, :primary],
              name: 'index_contacts_on_tenant_and_primary'
  end
end
