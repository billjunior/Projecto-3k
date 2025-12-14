class AddApprovalFieldsToEstimates < ActiveRecord::Migration[7.1]
  def change
    add_column :estimates, :approved_by, :string
    add_column :estimates, :approved_at, :datetime
  end
end
