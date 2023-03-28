# frozen_string_literal: true

# We need to require job processors before our gem
require "sidekiq"
require "resque"
require "resque-scheduler"
require "sqlite3"
require "delayed_job"
require "delayed_job_active_record"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "job_enqueue_logger"

require "logger"
require "minitest/autorun"

Sidekiq.configure_client do |config|
  config.logger = Logger.new(IO::NULL)
end

Delayed::Worker.default_queue_name = "default"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: "test/test_db.sqlite3")
ActiveRecord::Migration.verbose = false

require_relative "support/schema"

class TestCase < Minitest::Test
  def setup
    Sidekiq.redis(&:flushdb)
    Delayed::Job.delete_all
  end

  alias assert_not refute
  alias assert_not_match refute_match
end
