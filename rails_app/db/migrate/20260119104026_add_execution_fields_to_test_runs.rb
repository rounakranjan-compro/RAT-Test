class AddExecutionFieldsToTestRuns < ActiveRecord::Migration[6.1]
  def change
    # Associations
    add_reference :test_runs, :script, foreign_key: true unless column_exists?(:test_runs, :script_id)

    # Execution configuration
    add_column :test_runs, :environment, :string unless column_exists?(:test_runs, :environment)
    add_column :test_runs, :runner_mode, :string, default: "headless", null: false unless column_exists?(:test_runs, :runner_mode)
    add_column :test_runs, :retries_on_failure, :integer, default: 0, null: false unless column_exists?(:test_runs, :retries_on_failure)
    add_column :test_runs, :tags, :text unless column_exists?(:test_runs, :tags)

    # Status (already exists for you, so we only fix default if needed)
    change_column_default :test_runs, :status, "not_run"
  end
end

