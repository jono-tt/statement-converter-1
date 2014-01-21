require 'spec_helper'

describe EmailProcessor do
  subject { EmailProcessor }
  it { should respond_to(:process).with(1).argument }

  before(:each) do
    @card = create(:card, last_three_digits: "123")
  end

  it "should warn if incorrect source address" do
    email = build(:email, from: "not@stdbank.com")
    EmailProcessor.should_receive(:error).with("Email not from StandardBank: #{email.from}")
    EmailProcessor.process(email)
  end

  it "should log if no digits found in subject" do
    email = build(:email, subject: "no digits")
    EmailProcessor.should_receive(:error).with("Unable to find last three digits in the subject: no digits")
    EmailProcessor.process(email)
  end

  it "should log if no card found" do
    email = build(:email, subject: "StandardBank (456)")
    EmailProcessor.should_receive(:error).with("Unable to find card for digits: 456")
    EmailProcessor.process(email)
  end

  it "should log if no attachments" do
    email = build(:email)
    EmailProcessor.should_receive(:error).with("Unable to find any attachments")
    EmailProcessor.process(email)
  end

  it "should log no .emc attachment" do
    email = build(:email, :with_attachment)
    email.attachments.delete_if {|file| file.original_filename != 'hello_world.txt' } 

    EmailProcessor.should_receive(:error).with("Unable to find any attachments")
    EmailProcessor.process(email)
  end

  it "should have a bounce back when error logged" do
    EmailProcessor.should_receive(:bounce).with("Error: Foo Error", "Error")
    Rails.logger.should_receive(:error).with("Error: Foo Error")
    EmailProcessor.error("Foo Error")
  end

  it "should send a mail bounce back" do
    bouncer = Object.new
    bouncer.should_receive(:deliver)

    Rails.logger.should_receive(:info).with "Sending bounce message: support@complexes.co.za - Foo Message"
    BounceIncomingMailer.should_receive(:bounce).with("support@complexes.co.za", "Statement Converter: Success", "Foo Message").and_return bouncer

    EmailProcessor.bounce("Foo Message", "Success")
  end

  it "should decrypt email attachment" do
    email = build(:email, :with_attachment)
    EmailProcessor.should_receive(:error).with(an_instance_of(String), "Error - (123)")
    EmailProcessor.process(email)
  end

  it "should extract csv files" do
    email = build(:email, :with_attachment)
    dir = Rails.root.join('spec/fixtures', '*.csv')

    EmailProcessor.should_receive(:bounce).with(an_instance_of(String), "Success - (123)")
    EmailProcessor.should_receive(:extract_emc_csv_files).and_return(Dir.glob(dir))
    EmailProcessor.process(email)

    card = Card.find_by_last_three_digits("123")
    card.statement_items.length.should == 13

    item = card.statement_items[0]
    item.description.should == "INTEREST CAPITALISED"
    item.balance.should == 93349.47
    item.amount.should == 307.76
    item.transaction_date.should == Date.parse("02 December 2013")

    item = card.statement_items[10]
    item.description.should == "CREDIT TRANSFER ABSA BANK MI Madondo"
    item.balance.should == 14259.46
    item.amount.should == 1000
    item.transaction_date.should == Date.parse("07 Jan 2014")
  end
end
