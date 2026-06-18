class AddDefaultsToTests < ActiveRecord::Migration[6.1]
  def change
    add_column :tests, :tags, :string
    add_column :tests, :retries_on_failure, :integer
    add_column :tests, :runner_mode, :string
  end
end
