class AddMultipleContactsToCompanySettings < ActiveRecord::Migration[7.1]
  def change
    add_column :company_settings, :phones, :jsonb, default: []
    add_column :company_settings, :emails, :jsonb, default: []
    add_column :company_settings, :ibans, :jsonb, default: []
    add_column :company_settings, :bank_accounts, :jsonb, default: []
  end
end
