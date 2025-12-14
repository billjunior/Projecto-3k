class AddContactSourceToLeadsAndOpportunities < ActiveRecord::Migration[7.1]
  def change
    add_column :leads, :contact_source, :integer, default: 0
    add_column :opportunities, :contact_source, :integer, default: 0

    add_index :leads, :contact_source
    add_index :opportunities, :contact_source
  end
end
