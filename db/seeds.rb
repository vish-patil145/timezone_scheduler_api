User.destroy_all

User.create!(
  name: "India User",
  email: "india@test.com",
  timezone: "Asia/Kolkata",
  preferred_email_time: "09:00"
)

User.create!(
  name: "London User",
  email: "london@test.com",
  timezone: "Europe/London",
  preferred_email_time: "09:00"
)

User.create!(
  name: "New York User",
  email: "newyork@test.com",
  timezone: "America/New_York",
  preferred_email_time: "09:00"
)
