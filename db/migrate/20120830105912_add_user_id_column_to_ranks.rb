class AddUserIdColumnToRanks < ActiveRecord::Migration
  
  def up
    change_table :ranks do |t|
      t.references :user
    end
  end
  
  def down
    remove_column :ranks, :user_id
  end
  
end
