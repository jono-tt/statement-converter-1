class CreateCards < ActiveRecord::Migration
  def change
    create_table :cards do |t|
      t.string :last_three_digits, :null => false
      t.string :card_number, :null => false
      t.string :password, :null => false

      t.timestamps
    end

    add_index :cards, :last_three_digits, :unique => true
  end
end
