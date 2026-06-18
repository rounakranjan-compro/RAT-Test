class CreateRevokedTokens < ActiveRecord::Migration[6.1]
  def change
    create_table :revoked_tokens do |t|
      t.string :jti

      t.timestamps
    end
    add_index :revoked_tokens, :jti, unique: true
  end
end
