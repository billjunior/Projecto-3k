class AddDirectorContactsToCompanySettings < ActiveRecord::Migration[7.0]
  def change
    add_column :company_settings, :director_general_phone, :string
    add_column :company_settings, :director_general_whatsapp, :string
    add_column :company_settings, :financial_director_phone, :string
    add_column :company_settings, :financial_director_whatsapp, :string
  end
end
