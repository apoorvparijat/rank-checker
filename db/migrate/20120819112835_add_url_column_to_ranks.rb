class AddUrlColumnToRanks < ActiveRecord::Migration
  def change
    add_column :ranks, :url, :string
    add_column :ranks, :path, :string
  end
end
