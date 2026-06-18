class AddVncUrlToTestRuns < ActiveRecord::Migration[6.1]
  def change
    add_column :test_runs, :vnc_url, :string
  end
end
