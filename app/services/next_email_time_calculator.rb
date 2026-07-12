class NextEmailTimeCalculator
  def self.call(timezone, preferred_time)
    zone = ActiveSupport::TimeZone[timezone]

    now = zone.now

    scheduled_time = zone.local(
      now.year,
      now.month,
      now.day,
      preferred_time.hour,
      preferred_time.min,
      0
    )

    scheduled_time += 1.day if scheduled_time <= now

    scheduled_time.utc
  end
end
