class UserMailer < ApplicationMailer
  default from: "no-reply@example.com"

  def daily_email(user)
    @user = user

    mail(
      to: @user.email,
      subject: "Daily Reminder"
    )
  end
end
