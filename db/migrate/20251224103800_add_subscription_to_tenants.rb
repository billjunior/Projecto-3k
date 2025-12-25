class AddSubscriptionToTenants < ActiveRecord::Migration[7.1]
  def change
    add_column :tenants, :subscription_status, :string, default: 'trial'
    add_column :tenants, :subscription_expires_at, :datetime
    add_column :tenants, :subscription_plan, :string, default: 'monthly'
    add_column :tenants, :last_payment_date, :datetime
    add_column :tenants, :grace_period_days, :integer, default: 7

    add_index :tenants, :subscription_status
    add_index :tenants, :subscription_expires_at

    # Definir período de trial de 30 dias para tenants existentes
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE tenants
          SET subscription_expires_at = NOW() + INTERVAL '30 days',
              subscription_status = 'trial'
          WHERE subscription_expires_at IS NULL
        SQL
      end
    end
  end
end
