require 'spec_helper'

describe "cards/new" do
  before(:each) do
    assign(:card, stub_model(Card,
      :last_three_digits => "MyString",
      :card_number => "MyString",
      :password => "MyString"
    ).as_new_record)
  end

  it "renders new card form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => cards_path, :method => "post" do
      assert_select "input#card_last_three_digits", :name => "card[last_three_digits]"
      assert_select "input#card_card_number", :name => "card[card_number]"
      assert_select "input#card_password", :name => "card[password]"
    end
  end
end
