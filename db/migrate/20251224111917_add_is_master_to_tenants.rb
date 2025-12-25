class AddIsMasterToTenants < ActiveRecord::Migration[7.1]
  def change
    add_column :tenants, :is_master, :boolean
  end
end
