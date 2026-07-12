# Timezone Email Scheduler API

A Ruby on Rails API application that sends emails to users at their preferred local time, regardless of where they are in the world.

This project demonstrates how to build a scalable background scheduling system using:

- Ruby on Rails API
- PostgreSQL
- Sidekiq
- Redis
- Active Job
- Action Mailer
- Sidekiq Cron
- ActiveSupport::TimeZone
- IANA Time Zones
- UTC Time Storage

---

# Problem Statement

Suppose we have users located in different countries.

| User | Timezone | Preferred Email Time |
|------|----------|----------------------|
| John | Asia/Kolkata | 09:00 AM |
| Alice | America/New_York | 09:00 AM |
| Bob | Europe/London | 09:00 AM |

Every user wants to receive an email at **09:00 AM according to their own local timezone**.

Even if the application server runs in UTC, every user should receive the email at their local 9 AM.

---

# Solution

Instead of checking every user's timezone every minute, the application converts each user's preferred local time into UTC once and stores it in the database.

Example:

| User | Local Time | Stored in Database (UTC) |
|------|------------|--------------------------|
| India | 09:00 AM | 03:30 UTC |
| London | 09:00 AM | 08:00 UTC |
| New York | 09:00 AM | 13:00 UTC |

The scheduler simply checks:

```ruby
User.where(next_email_at: ..Time.current)
```

Since everything is stored in UTC, no timezone conversion is required while scheduling.

---

# Technology Stack

| Technology | Purpose |
|------------|---------|
| Ruby on Rails API | REST API |
| PostgreSQL | Database |
| Redis | Background Job Queue |
| Sidekiq | Background Job Processing |
| Active Job | Job Interface |
| Sidekiq Cron | Run Scheduler Every Minute |
| Action Mailer | Send Emails |
| ActiveSupport::TimeZone | Timezone Conversion |
| IANA Time Zones | Store User Timezones |
| UTC | Standard Time Storage |

---

# Database Design

## Users Table

| Column | Description |
|---------|-------------|
| id | User ID |
| name | User Name |
| email | Email Address |
| timezone | IANA Timezone |
| preferred_email_time | User Selected Local Time |
| next_email_at | Next Email Time Stored in UTC |

Example:

| Name | Timezone | Preferred Time | next_email_at |
|------|----------|----------------|---------------|
| John | Asia/Kolkata | 09:00 AM | 03:30 UTC |

---

# How Multiple Timezones Are Handled

Suppose three users choose **09:00 AM**.

```
India User
09:00 AM IST
        │
        ▼
03:30 UTC


London User
09:00 AM GMT
        │
        ▼
08:00 UTC


New York User
09:00 AM EST
        │
        ▼
13:00 UTC
```

Only the UTC value is stored in the database.

The scheduler compares UTC timestamps only.

Rails automatically converts between the user's local timezone and UTC whenever required.

---

# Why IANA Timezones?

Instead of storing:

```
UTC+5:30
UTC-5
UTC+1
```

We store:

```
Asia/Kolkata
America/New_York
Europe/London
Australia/Sydney
```

### Advantages

- Handles Daylight Saving Time (DST)
- Automatically adjusts timezone changes
- Rails recommended approach
- International standard

---

# Project Architecture

```
                     Every Minute
                           │
                           ▼
                  Sidekiq Cron Scheduler
                           │
                           ▼
                 EmailSchedulerJob
                           │
                           ▼
       Find Users where next_email_at <= Time.current
                           │
                           ▼
          SendEmailJob.perform_later(user.id)
                           │
                           ▼
                    Redis Queue
                           │
                           ▼
                    Sidekiq Worker
                           │
                           ▼
                    Action Mailer
                           │
                           ▼
                      Send Email
                           │
                           ▼
        Update next_email_at for Tomorrow
```

---

# Complete Flow

## Step 1

User registers.

```
Name : John

Timezone : America/New_York

Preferred Email Time : 09:00 AM
```

---

## Step 2

Application converts

```
09:00 AM New York

↓

13:00 UTC
```

---

## Step 3

Store in database

```
next_email_at = 13:00 UTC
```

---

## Step 4

Every minute

Sidekiq Cron executes

```
EmailSchedulerJob
```

---

## Step 5

Scheduler finds users

```ruby
User.where(next_email_at: ..Time.current)
```

---

## Step 6

Scheduler pushes jobs into Redis

```ruby
SendEmailJob.perform_later(user.id)
```

---

## Step 7

Sidekiq Worker processes the job

```
UserMailer.daily_email(user)
```

---

## Step 8

Email is delivered.

---

## Step 9

Application calculates tomorrow's schedule.

```
Tomorrow 09:00 AM

↓

Convert to UTC

↓

Update next_email_at
```

The same process repeats every day.

---

# Why Background Jobs?

Instead of sending emails directly:

```
Scheduler

↓

Send Email

↓

Wait

↓

Send Email

↓

Wait
```

We do this:

```
Scheduler

↓

Queue Jobs

↓

Sidekiq Workers

↓

Send Emails in Parallel
```

### Benefits

- Faster
- Parallel Processing
- Automatic Retry
- Failure Handling
- Highly Scalable

---

# Why Store UTC?

Regardless of where the application server is deployed,

```
Database

↓

Always stores UTC
```

Only while calculating the next schedule does Rails convert the user's local time into UTC.

---

# Project Structure

```
app/

├── jobs/
│   ├── email_scheduler_job.rb
│   └── send_email_job.rb
│
├── mailers/
│   └── user_mailer.rb
│
├── models/
│   └── user.rb
│
├── services/
│   └── next_email_time_calculator.rb
│
config/
│
├── initializers/
│   └── sidekiq.rb
│
└── sidekiq.yml
```

---

# Setup Instructions

## Clone Repository

```bash
git clone <repository_url>

cd timezone_scheduler_api
```

---

## Install Gems

```bash
bundle install
```

---

## Create Database

```bash
rails db:create

rails db:migrate
```

---

## Seed Database

```bash
rails db:seed
```

---

## Start Redis

```bash
redis-server
```

---

## Start Sidekiq

```bash
bundle exec sidekiq -C config/sidekiq.yml
```

---

## Start Rails

```bash
rails server
```

---

# How to Test

## Step 1

Create a User.

```
POST /api/v1/users
```

Example Request

```json
{
  "user": {
    "name": "John",
    "email": "john@test.com",
    "timezone": "Asia/Kolkata",
    "preferred_email_time": "09:00"
  }
}
```

---

## Step 2

Verify Database

```
preferred_email_time

09:00 AM

↓

next_email_at

03:30 UTC
```

---

## Step 3

Open Rails Console

```bash
rails console
```

---

## Step 4

Force email to become due.

```ruby
user = User.first

user.update!(next_email_at: Time.current)
```

---

## Step 5

Wait one minute.

Scheduler will automatically enqueue the email job.

---

## Step 6

Observe Sidekiq logs.

```
EmailSchedulerJob

↓

SendEmailJob

↓

Email Sent
```

---

## Step 7

Open Letter Opener

```
http://localhost:3000/letter_opener
```

Verify that the email has been delivered.

---

## Step 8

Verify Database Again

```
next_email_at

↓

Tomorrow's UTC Time
```

The scheduler has successfully updated the next execution time.

---

# Design Decisions

- API-only Rails application
- Store IANA timezone names instead of UTC offsets
- Store next scheduled execution in UTC
- Use Sidekiq for asynchronous processing
- Use Redis as the job queue
- Use Sidekiq Cron to trigger the scheduler every minute
- Keep scheduling and email delivery as separate jobs (Single Responsibility Principle)
- Use indexed database queries for scalability

---

# Future Improvements

- Prevent duplicate scheduling using row-level locking (`FOR UPDATE SKIP LOCKED`)
- Add an `email_logs` table for idempotency
- Add retry policies for failed deliveries
- Add RSpec tests
- Add monitoring and metrics
- Add user APIs to update preferred email time and timezone

---

# Summary

This project demonstrates how to build a production-ready, timezone-aware email scheduling system.

Key highlights:

- Supports users from multiple countries.
- Sends emails according to each user's local timezone.
- Stores all schedules in UTC.
- Uses Sidekiq and Redis for scalable background processing.
- Uses Rails ActiveSupport::TimeZone with IANA timezone identifiers.
- Designed to handle millions of users efficiently using indexed UTC queries.