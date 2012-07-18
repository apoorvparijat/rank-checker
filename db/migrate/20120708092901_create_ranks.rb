class CreateRanks < ActiveRecord::Migration
  def change
    create_table :ranks do |t|
      t.string :domain
      t.text :keyword
      t.integer :page
      t.integer :position
      t.integer :rank
      t.string :ip

      t.timestamps
    end
  end
end
