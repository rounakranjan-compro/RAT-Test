class CreateTests < ActiveRecord::Migration[6.1]
  def change
    create_table :tests do |t|
      t.string :title
      t.string :environment
      t.string :tags
      t.references :script, null: false, foreign_key: true

      t.timestamps
    end
  end
end
