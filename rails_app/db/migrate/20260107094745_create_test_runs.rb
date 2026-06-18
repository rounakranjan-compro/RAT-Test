class CreateTestRuns < ActiveRecord::Migration[6.1]
  def change
    create_table :test_runs do |t|
      t.references :test, null: false, foreign_key: true
      t.string :status
      t.datetime :started_at
      t.datetime :finished_at

      t.timestamps
    end
  end
end
