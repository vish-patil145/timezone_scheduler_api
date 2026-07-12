class SendEmailJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find_by(id: user_id)

    return unless user

    UserMailer.daily_email(user).deliver_now

    user.update!(
      next_email_at: NextEmailTimeCalculator.call(
        user.timezone,
        user.preferred_email_time
      )
    )
  end
end
