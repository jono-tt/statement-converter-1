require 'spec_helper'

describe "cards/index" do
  before(:each) do
    assign(:cards, [
      stub_model(Card,
        :last_three_digits => "Last Three Digits",
        :card_number => "123",
        :password => "Password"
      ),
      stub_model(Card,
        :last_three_digits => "Last Three Digits",
        :card_number => "456",
        :password => "Password"
      )
    ])
  end

  it "renders a list of cards" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Last Three Digits".to_s, :count => 2
    assert_select "tr>td", :text => "123".to_s, :count => 1
    assert_select "tr>td", :text => "456".to_s, :count => 1
  end
end
