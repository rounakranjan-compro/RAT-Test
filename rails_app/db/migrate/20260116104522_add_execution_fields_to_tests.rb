class AddExecutionFieldsToTests < ActiveRecord::Migration[6.1]
  def change
    add_column :tests, :runner_mode, :string, null: false, default: "headless"
    add_column :tests, :retries_on_failure, :integer, null: false, default: 0
  end
end

