class AddProfitMarginToCompanySettings < ActiveRecord::Migration[7.1]
  def change
    add_column :company_settings, :default_profit_margin, :decimal,
               precision: 5, scale: 2, default: 65.0, null: false
  end
end
