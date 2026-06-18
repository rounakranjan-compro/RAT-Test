class AddFileUrlToArtifacts < ActiveRecord::Migration[6.1]
  def change
    add_column :artifacts, :file_url, :string
  end
end
