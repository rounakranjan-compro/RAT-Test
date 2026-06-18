class CleanupTestsAndFixTestRuns < ActiveRecord::Migration[6.1]
  def change
    # Remove execution fields from tests
    remove_column :tests, :environment, :string if column_exists?(:tests, :environment)
    remove_column :tests, :runner_mode, :string if column_exists?(:tests, :runner_mode)
    remove_column :tests, :retries_on_failure, :integer if column_exists?(:tests, :retries_on_failure)
    remove_column :tests, :tags, :string if column_exists?(:tests, :tags)

    # Fix test_runs.environment to be NOT NULL
    if column_exists?(:test_runs, :environment)
      execute <<~SQL
        UPDATE test_runs SET environment = 'QA' WHERE environment IS NULL;
      SQL

      change_column_null :test_runs, :environment, false
    end
  end
end
