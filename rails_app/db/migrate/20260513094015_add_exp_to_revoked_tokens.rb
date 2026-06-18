class AddExpToRevokedTokens < ActiveRecord::Migration[6.1]
  def change
    add_column :revoked_tokens, :exp, :datetime
  end
end
