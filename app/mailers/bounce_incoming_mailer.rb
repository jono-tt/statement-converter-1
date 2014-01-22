class BounceIncomingMailer < ActionMailer::Base
  default from: "Statements <statements@complexes.co.za>"

  def bounce(recipient, subject, message, attachment = nil)
    if attachment != nil
      add_attachment(attachment)
    end
      
    mail(to: recipient, subject: subject, body: message)
  end

  def add_attachment(attachment)
    attachments[attachment[:filename]] = {:mime_type => attachment[:mime_type], :content => attachment[:content] }
  end
end
