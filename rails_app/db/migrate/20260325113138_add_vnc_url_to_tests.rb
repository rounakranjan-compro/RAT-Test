class AddVncUrlToTests < ActiveRecord::Migration[6.1]
  def change
    add_column :tests, :vnc_url, :string
  end
end
