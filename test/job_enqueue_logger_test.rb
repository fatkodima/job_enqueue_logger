# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/sidekiq_jobs"

class JobEnqueueLoggerTest < TestCase
  BACKTRACE_LINE_RE = /:\d+:in/

  def test_backtrace_is_disabled_by_default
    output = capture_logging do
      SidekiqJobs::TestJob.perform_async
    end
    assert_match("Enqueued SidekiqJobs::TestJob", output)
    assert_not_match(/#{BACKTRACE_LINE_RE} `#{__method__}/, output)
  end

  def test_backtrace_is_enabled
    JobEnqueueLogger.backtrace = true

    output = capture_logging do
      SidekiqJobs::TestJob.perform_async
    end
    assert_match(/#{BACKTRACE_LINE_RE} `#{__method__}/, output)
  ensure
    JobEnqueueLogger.backtrace = false
  end

  def test_backtrace_is_limited
    JobEnqueueLogger.backtrace = 3

    output = capture_logging do
      SidekiqJobs::TestJob.perform_async
    end
    lines_count = output.lines.count { |line| line.match?(BACKTRACE_LINE_RE) }
    assert_equal 3, lines_count
  ensure
    JobEnqueueLogger.backtrace = false
  end

  def test_backtrace_cleaner
    JobEnqueueLogger.backtrace = true
    previous_cleaner = JobEnqueueLogger.backtrace_cleaner

    JobEnqueueLogger.backtrace_cleaner = ->(_backtrace) { ["my_custom_location"] }
    output = capture_logging do
      SidekiqJobs::TestJob.perform_async
    end
    assert_not_match(BACKTRACE_LINE_RE, output)
    assert_match("my_custom_location", output)
  ensure
    JobEnqueueLogger.backtrace = false
    JobEnqueueLogger.backtrace_cleaner = previous_cleaner
  end

  class TestBacktraceCleaner
    def clean(_backtrace)
      ["my_custom_location"]
    end
  end

  def test_backtrace_cleaner_not_callable
    JobEnqueueLogger.backtrace = true
    previous_cleaner = JobEnqueueLogger.backtrace_cleaner

    JobEnqueueLogger.backtrace_cleaner = TestBacktraceCleaner.new
    output = capture_logging do
      SidekiqJobs::TestJob.perform_async
    end
    assert_not_match(BACKTRACE_LINE_RE, output)
    assert_match("my_custom_location", output)
  ensure
    JobEnqueueLogger.backtrace = false
    JobEnqueueLogger.backtrace_cleaner = previous_cleaner
  end

  private
    def capture_logging(&block)
      out = StringIO.new
      logger = Logger.new(out)
      logger.level = Sidekiq.logger.level
      Sidekiq.stub(:logger, logger, &block)
      out.string
    end
end
