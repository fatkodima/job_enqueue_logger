# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in job_enqueue_logger.gemspec
gemspec

gem "rake", "~> 13.0"
gem "minitest", "~> 5.0"
gem "rubocop", "< 2"
gem "rubocop-minitest"

if defined?(@sidekiq_requirement)
  gem "sidekiq", @sidekiq_requirement
else
  gem "sidekiq" # latest
end

if defined?(@resque_requirement)
  gem "resque", @resque_requirement
else
  gem "resque"
end

gem "resque-scheduler"

if defined?(@delayed_job_requirement)
  gem "delayed_job", @delayed_job_requirement
else
  gem "delayed_job"
end

gem "delayed_job_active_record"
gem "sqlite3" # needed for delayed_job
