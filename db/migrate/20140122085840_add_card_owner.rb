class AddCardOwner < ActiveRecord::Migration
  def up
    add_column :cards, :account_name, :string
  end

  def down
    remove_column :cards, :account_name
  end
end
