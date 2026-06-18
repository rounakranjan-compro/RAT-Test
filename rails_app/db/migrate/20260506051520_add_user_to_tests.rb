# db/migrate/20260506051520_add_user_to_tests.rb
class AddUserToTests < ActiveRecord::Migration[6.1]
  def change
    add_reference :tests, :user, null: false, foreign_key: true
  end
end
