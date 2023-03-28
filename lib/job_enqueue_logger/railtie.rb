# frozen_string_literal: true

require "rails"

module JobEnqueueLogger
  class Railtie < Rails::Railtie
    initializer "job_enqueue_logger.backtrace_cleaner" do
      JobEnqueueLogger.backtrace_cleaner = Rails.backtrace_cleaner
    end
  end
end
