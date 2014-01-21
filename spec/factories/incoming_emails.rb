include ActionDispatch::TestProcess

FactoryGirl.define do
  factory :email, class: OpenStruct do
    to [{ raw: 'incoming@email.com', email: 'incoming@email.com', host: 'email.com' }]
    from 'ibsupport@standardbank.co.za'
    subject 'Standard Bank (123)'
    body 'Hello!'
    attachments {[]}

    trait :with_attachment do
      attachments {[
        fixture_file_upload(Rails.root.to_s + '/spec/fixtures/hello_world.txt', 'text/plain'),
        fixture_file_upload(Rails.root.to_s + '/spec/fixtures/SBSA_Statement.emc', 'application/oct')
      ]}
    end
  end
end
