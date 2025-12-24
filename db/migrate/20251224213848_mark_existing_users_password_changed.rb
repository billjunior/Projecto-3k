class MarkExistingUsersPasswordChanged < ActiveRecord::Migration[7.1]
  def up
    # Mark all existing users as having already changed their password
    # Only new users created after this migration will need to change password on first login
    User.update_all(must_change_password: false, password_changed_at: Time.current)
  end

  def down
    # No rollback needed
  end
end
