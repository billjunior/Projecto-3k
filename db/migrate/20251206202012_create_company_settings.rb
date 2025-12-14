class CreateCompanySettings < ActiveRecord::Migration[7.1]
  def change
    create_table :company_settings do |t|
      t.references :tenant, null: false, foreign_key: true
      t.string :company_name
      t.text :address
      t.string :email
      t.string :phone
      t.string :iban
      t.string :company_tagline, default: "3K - Soluções Gráficas, uma empresa do grupo ITTECH"

      t.timestamps
    end
  end
end
