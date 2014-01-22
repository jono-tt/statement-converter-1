include ActionDispatch::TestProcess

FactoryGirl.define do
  factory :card do
    account_name { /\w{4}/.gen }
    last_three_digits { /\d{3}/.gen }
    card_number { /\d{9}/.gen }
    password { /\w{10}/.gen }
  end
end
