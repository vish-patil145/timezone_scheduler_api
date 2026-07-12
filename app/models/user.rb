class User < ApplicationRecord
  validates :name, :email, :timezone, :preferred_email_time, presence: true
  validates :email, uniqueness: true

  validates :timezone,
            inclusion: {
              in: ActiveSupport::TimeZone.all.map(&:tzinfo).map(&:name)
            }

  before_create :calculate_next_email_at

  private

  def calculate_next_email_at
    self.next_email_at = NextEmailTimeCalculator.call(
      timezone,
      preferred_email_time
    )
  end
end
