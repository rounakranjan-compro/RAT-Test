class AddDeviseOauthToUsers < ActiveRecord::Migration[6.1]
  def change
    # Remove plain password column we added earlier
    remove_column :users, :password, :string

    # Devise database_authenticatable (needed even for OAuth)
    add_column :users, :encrypted_password, :string, null: false, default: ''

    # OmniAuth Google
    add_column :users, :provider, :string
    add_column :users, :uid,      :string

    add_index :users, [:provider, :uid], unique: true
  end
end
