class EmailSchedulerJob < ApplicationJob
  queue_as :default

  def perform
    User
      .where(next_email_at: ..Time.current)
      .find_each(batch_size: 500) do |user|
      SendEmailJob.perform_later(user.id)
    end
  end
end
