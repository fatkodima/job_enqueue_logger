# frozen_string_literal: true

require_relative "job_enqueue_logger/version"
require_relative "job_enqueue_logger/utils"

module JobEnqueueLogger
  class << self
    attr_reader :backtrace_cleaner

    def backtrace_cleaner=(cleaner)
      @backtrace_cleaner =
        if cleaner.respond_to?(:clean)
          ->(backtrace) { cleaner.clean(backtrace) }
        else
          cleaner
        end
    end

    attr_accessor :backtrace

    def configure
      yield self
    end
  end

  self.backtrace_cleaner = ->(backtrace) { backtrace }
  self.backtrace = false
end

require_relative "job_enqueue_logger/sidekiq_adapter" if defined?(Sidekiq)
require_relative "job_enqueue_logger/resque_adapter" if defined?(Resque)
require_relative "job_enqueue_logger/railtie" if defined?(Rails)
