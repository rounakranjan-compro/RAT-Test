class AddEnvironmentToTests < ActiveRecord::Migration[6.1]
  def change
    add_column :tests, :environment, :string
  end
end
