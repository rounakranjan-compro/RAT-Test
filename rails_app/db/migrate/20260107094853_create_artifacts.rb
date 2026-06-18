class CreateArtifacts < ActiveRecord::Migration[6.1]
  def change
    create_table :artifacts do |t|
      t.references :test_run, null: false, foreign_key: true
      t.string :kind
      t.jsonb :metadata

      t.timestamps
    end
  end
end
