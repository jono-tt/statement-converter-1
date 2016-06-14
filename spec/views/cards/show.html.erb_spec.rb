require 'spec_helper'

describe "cards/show" do
  before(:each) do
    @card = assign(:card, stub_model(Card,
      :last_three_digits => "Last Three Digits",
      :card_number => "Card Number",
      :password => "Password"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Last Three Digits/)
    rendered.should match(/Card Number/)
    rendered.should match(/Password/)
  end
end
