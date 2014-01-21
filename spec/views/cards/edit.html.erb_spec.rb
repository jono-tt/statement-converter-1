require 'spec_helper'

describe "cards/edit" do
  before(:each) do
    @card = assign(:card, build(:card))
  end

  it "renders the edit card form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => cards_path(@card), :method => "post" do
      assert_select "input#card_last_three_digits", :name => "card[last_three_digits]"
      assert_select "input#card_card_number", :name => "card[card_number]"
      assert_select "input#card_password", :name => "card[password]"
    end
  end
end
