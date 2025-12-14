class UpdateUsersForSecurityArchitecture < ActiveRecord::Migration[7.1]
  def change
    # Add department enum field
    add_column :users, :department, :integer
    add_index :users, :department

    # Add admin boolean field
    add_column :users, :admin, :boolean, default: false, null: false
    add_index :users, :admin

    # Enable Devise Trackable module
    add_column :users, :sign_in_count, :integer, default: 0, null: false
    add_column :users, :current_sign_in_at, :datetime
    add_column :users, :last_sign_in_at, :datetime
    add_column :users, :current_sign_in_ip, :string
    add_column :users, :last_sign_in_ip, :string

    # Enable Devise Lockable module
    add_column :users, :failed_attempts, :integer, default: 0, null: false
    add_column :users, :unlock_token, :string
    add_column :users, :locked_at, :datetime
    add_index :users, :unlock_token, unique: true

    # Enable Devise Confirmable module
    add_column :users, :confirmation_token, :string
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime
    add_column :users, :unconfirmed_email, :string
    add_index :users, :confirmation_token, unique: true

    # Nota: O enum role será atualizado no model User diretamente
    # Os valores existentes serão mantidos compatíveis:
    # Novo mapeamento: { commercial: 0, cyber_tech: 1, attendant: 2, production: 3 }
    # Será necessário migrar dados se houver usuários existentes
  end
end
