class CreateStatementItems < ActiveRecord::Migration
  def change
    create_table :statement_items do |t|
      t.string :description, :null => false
      t.decimal :amount, :null => false, :precision => 12, :scale => 3
      t.decimal :balance, :null => false, :precision => 12, :scale => 3
      t.string :transaction_type, :null => false
      t.date :transaction_date, :null => false

      t.references :card
      t.timestamps
    end

    add_index(:statement_items, [:amount, :balance, :transaction_date])
  end
end
