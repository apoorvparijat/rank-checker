class ModifyPasswordColumnName < ActiveRecord::Migration
  def up
    rename_column(:users, :password_digest, :password)
  end

  def down
    rename_column(:users, :password, :password_digest)
  end
end
