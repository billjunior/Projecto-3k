class AddMustChangePasswordToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :must_change_password, :boolean, default: true, null: false
    add_column :users, :password_changed_at, :datetime
  end
end
