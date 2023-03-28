# frozen_string_literal: true

# We need to require job processors before our gem
require "sidekiq"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "job_enqueue_logger"

require "logger"
require "minitest/autorun"

Sidekiq.configure_client do |config|
  config.logger = Logger.new(IO::NULL)
end
