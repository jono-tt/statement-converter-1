# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20140205010940) do

  create_table "cards", :force => true do |t|
    t.string   "last_three_digits", :null => false
    t.string   "card_number",       :null => false
    t.string   "password",          :null => false
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
    t.string   "account_name"
  end

  add_index "cards", ["last_three_digits"], :name => "index_cards_on_last_three_digits", :unique => true

  create_table "statement_items", :force => true do |t|
    t.string   "description",                                     :null => false
    t.decimal  "amount",           :precision => 12, :scale => 3, :null => false
    t.decimal  "balance",          :precision => 12, :scale => 3, :null => false
    t.string   "transaction_type",                                :null => false
    t.date     "transaction_date",                                :null => false
    t.integer  "card_id"
    t.datetime "created_at",                                      :null => false
    t.datetime "updated_at",                                      :null => false
    t.string   "statement_type"
  end

  add_index "statement_items", ["amount", "balance", "transaction_date"], :name => "index_statement_items_on_amount_and_balance_and_transaction_date"
  add_index "statement_items", ["card_id", "transaction_date", "statement_type"], :name => "cid_and_trans_date_and_stype"

end
