class AddMissingItemsEmailsToCompanySettings < ActiveRecord::Migration[7.1]
  def change
    add_column :company_settings, :director_general_email, :string
    add_column :company_settings, :financial_director_email, :string
  end
end
