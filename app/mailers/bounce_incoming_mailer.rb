class BounceIncomingMailer < ActionMailer::Base
  default from: "Statements <statements@complexes.co.za>"

  def bounce(recipient, subject, message)
    mail(to: recipient, subject: subject, body: message)
  end
end
