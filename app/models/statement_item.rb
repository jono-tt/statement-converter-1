class StatementItem < ActiveRecord::Base
  attr_accessible :amount, :balance, :description, :transaction_date, :transaction_type, :statement_type

  belongs_to :card
end
