require 'spec_helper'

describe EmailProcessor do
  subject { EmailProcessor }
  it { should respond_to(:process).with(1).argument }

  before(:each) do
    @card = create(:card, last_three_digits: "123")
  end

  #TODO: Add once this is enforced
  # it "should warn if incorrect source address" do
  #   email = build(:email, from: "not@stdbank.com")
  #   EmailProcessor.should_receive(:error).with("Email not from StandardBank: #{email.from}")
  #   EmailProcessor.process(email)
  # end

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

    Rails.logger.should_receive(:info).with "Sending bounce message: import@complexes.co.za - Foo Message"
    BounceIncomingMailer.should_receive(:bounce).with("import@complexes.co.za", "Statement Converter: Success", "Foo Message").and_return bouncer

    EmailProcessor.bounce("Foo Message", "Success")
  end

  it "should decrypt email attachment" do
    email = build(:email, :with_attachment)
    EmailProcessor.should_receive(:error).with(an_instance_of(String), "Error - (#{@card.account_name}: 123)")
    EmailProcessor.process(email)
  end

  it "should bound error if no csv files found" do
    email = build(:email, :with_attachment)
    emcs = email.attachments.select { |file| file.original_filename.match(/emc$/) }

    card = Card.find_by_last_three_digits("123")

    EmailProcessor.should_receive(:error).with("No csv files found to process", "Error - (#{@card.account_name}: 123)")

    EmailProcessor.should_receive(:extract_emc_csv_files).and_return([])
    EmailProcessor.process(email)
  end

  it "should extract csv files" do
    email = build(:email, :with_attachment)
    emcs = email.attachments.select { |file| file.original_filename.match(/emc$/) }

    card = Card.find_by_last_three_digits("123")

    dir = Rails.root.join('spec/fixtures', '*.csv')

    EmailProcessor.should_receive(:bounce_with_attachment) do | msg, type, attachment_base_name, imported_files |
      type.should == "Success - (#{@card.account_name}: 123)"
      attachment_base_name.should == "#{@card.account_name}-c123_#{File.basename(emcs[0].path)}"
      imported_files.length.should == 2

      #TYPE: MARKETLINK
      imported_files[0][:statement_items].length.should == 7
      imported_files[0][:statement_type].should == "MARKETLINK"

      #TYPE: CURRENT ACC
      imported_files[1][:statement_items].length.should == 10
      imported_files[1][:statement_type].should == "CURRENT ACC"
    end

    EmailProcessor.should_receive(:extract_emc_csv_files).and_return(Dir.glob(dir))
    EmailProcessor.process(email)

    card.statement_items.length.should == 17

    item = card.statement_items[0]
    item.description.should == "####### OPENING BALANCE:  93041.71 #######"
    item.balance.should == BigDecimal(93041.71, 12)
    item.amount.should == 0
    item.transaction_date.should == Date.parse("02 December 2013")
    item.statement_type.should == "MARKETLINK"

    item = card.statement_items[1]
    item.description.should == "INTEREST CAPITALISED"
    item.balance.should == 93349.47
    item.amount.should == 307.76
    item.transaction_date.should == Date.parse("02 December 2013")
    item.statement_type.should == "MARKETLINK"

    item = card.statement_items[15]
    item.description.should == "CREDIT TRANSFER ABSA BANK MI Madondo"
    item.balance.should == 14439.46
    item.amount.should.to_s == 900
    item.transaction_date.should == Date.parse("09 Jan 2014")
    item.statement_type.should == "CURRENT ACC"

    item = card.statement_items[16]
    item.description.should == "####### CLOSING BALANCE: 14439.46 #######"
    item.balance.should == BigDecimal(14439.46, 12)
    item.amount.should == 0
    item.transaction_date.should == Date.parse("13 Jan 2014")
    item.statement_type.should == "CURRENT ACC"
  end
end
