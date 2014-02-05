class AddStatementTypeToStatementItem < ActiveRecord::Migration
  def up
    add_column :statement_items, :statement_type, :string
    add_index :statement_items, [:card_id, :transaction_date, :statement_type], :name => "cid_and_trans_date_and_stype"
  end

  def down
    remove_index :statement_items, :name => "cid_and_trans_date_and_stype"
    remove_column :statement_items, :statement_type
  end
end
