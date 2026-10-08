class AdminMailer < ApplicationMailer
  def invitation_email(name, email, invitation_link)
    @name = name
    @invitation_link = invitation_link

    mail(
      to: email,
      subject: "Invitation - Sample Request Automation"
    )
  end
end