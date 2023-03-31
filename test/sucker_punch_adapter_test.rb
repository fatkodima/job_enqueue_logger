# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/sucker_punch_jobs"

class SuckerPunchAdapterTest < TestCase
  def setup
    super
    SuckerPunch::Queue.clear
  end

  def test_perform_async
    output = capture_logging do
      enqueued = SuckerPunchJobs::TestJob.perform_async
      assert_equal true, enqueued
    end
    assert_match("Enqueued SuckerPunchJobs::TestJob to SuckerPunch", output)
  end

  def test_perform_async_with_arguments
    output = capture_logging do
      SuckerPunchJobs::TestJobWithArguments.perform_async(1, 2)
    end
    assert_match(" with arguments: 1, 2", output)
  end

  def test_perform_async_is_not_enqueued_if_sucker_punch_is_shutdown
    with_sucker_punch_shutdown do
      output = capture_logging do
        enqueued = SuckerPunchJobs::TestJob.perform_async
        assert_nil enqueued
      end
      assert_empty output
    end
  end

  def test_perform_in
    output = capture_logging do
      enqueued = SuckerPunchJobs::TestJob.perform_in(60)
      assert_equal true, enqueued
    end
    assert_match(/Enqueued SuckerPunchJobs::TestJob to SuckerPunch in 60 seconds \(at .+\)/i, output)
  end

  def test_perform_in_with_arguments
    output = capture_logging do
      enqueued = SuckerPunchJobs::TestJob.perform_in(60, 1, 2)
      assert_equal true, enqueued
    end
    assert_match(/Enqueued SuckerPunchJobs::TestJob to SuckerPunch in 60 seconds \(at .+\) with arguments: 1, 2/i, output)
  end

  def test_perform_in_is_not_enqueued_if_sucker_punch_is_shutdown
    with_sucker_punch_shutdown do
      output = capture_logging do
        enqueued = SuckerPunchJobs::TestJob.perform_in(60)
        assert_nil enqueued
      end
      assert_empty output
    end
  end

  def test_logging_when_child_job_is_enqueued
    output = capture_logging do
      SuckerPunchJobs::ParentJob.perform_async
      queue = SuckerPunch::Queue.find_or_create("SuckerPunchJobs::ParentJob")
      queue.shutdown
      queue.wait_for_termination(1)
    end
    assert_match('Enqueued SuckerPunchJobs::TestJobWithArguments to SuckerPunch with arguments: "from_parent"', output)
  end

  private
    def capture_logging(&block)
      out = StringIO.new
      logger = Logger.new(out)
      SuckerPunch.stub(:logger, logger, &block)
      out.string
    end

    def with_sucker_punch_shutdown
      SuckerPunch::RUNNING.make_false
      yield
    ensure
      SuckerPunch::RUNNING.make_true
    end
end
