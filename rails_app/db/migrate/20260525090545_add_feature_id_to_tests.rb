class AddFeatureIdToTests < ActiveRecord::Migration[6.1]
  def change
    add_reference :tests, :feature, null: true, foreign_key: true
  end
end
