# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/resque_jobs"

class ResqueAdapterTest < TestCase
  def test_enqueue
    output = capture_logging do
      enqueued = Resque.enqueue(ResqueJobs::TestJob)
      assert_equal true, enqueued
    end
    assert_match("Enqueued ResqueJobs::TestJob to Resque(default)", output)
  end

  def test_enqueue_with_arguments
    output = capture_logging { Resque.enqueue(ResqueJobs::TestJobWithArguments, 1, 2) }
    assert_match("Enqueued ResqueJobs::TestJobWithArguments to Resque(default) with arguments: 1, 2", output)
  end

  def test_enqueue_when_inline_is_set
    Resque.inline = true
    output = capture_logging do
      enqueued = Resque.enqueue(ResqueJobs::TestJobWithArguments, 1, 2)
      assert_equal true, enqueued
    end
    assert_match("Performed inline ResqueJobs::TestJobWithArguments with arguments: 1, 2", output)
  ensure
    Resque.inline = false
  end

  def test_enqueue_halted_by_callback
    output = capture_logging do
      enqueued = Resque.enqueue(ResqueJobs::TestJobWithHook)
      assert_nil enqueued
    end
    assert_empty output
  end

  def test_enqueue_to
    output = capture_logging do
      enqueued = Resque.enqueue_to(:my_queue, ResqueJobs::TestJob)
      assert_equal true, enqueued
    end
    assert_match("Enqueued ResqueJobs::TestJob to Resque(my_queue)", output)
  end

  def test_enqueue_to_with_arguments
    output = capture_logging { Resque.enqueue_to(:my_queue, ResqueJobs::TestJobWithArguments, 1, 2) }
    assert_match("Enqueued ResqueJobs::TestJobWithArguments to Resque(my_queue) with arguments: 1, 2", output)
  end

  def test_enqueue_to_when_inline_is_set
    Resque.inline = true
    output = capture_logging do
      enqueued = Resque.enqueue_to(:my_queue, ResqueJobs::TestJobWithArguments, 1, 2)
      assert_equal true, enqueued
    end
    assert_match("Performed inline ResqueJobs::TestJobWithArguments with arguments: 1, 2", output)
  ensure
    Resque.inline = false
  end

  def test_enqueue_to_halted_by_callback
    output = capture_logging do
      enqueued = Resque.enqueue_to(:my_queue, ResqueJobs::TestJobWithHook)
      assert_nil enqueued
    end
    assert_empty output
  end

  def test_enqueue_at
    output = capture_logging do
      Resque.enqueue_at(Time.now + 10, ResqueJobs::TestJobWithArguments, 1, 2)
    end
    assert_match(/Enqueued ResqueJobs::TestJobWithArguments to Resque\(default\) at .+ with arguments: 1, 2/i, output)
  end

  def test_enqueue_at_with_queue
    output = capture_logging do
      Resque.enqueue_at_with_queue(:my_queue, Time.now + 10, ResqueJobs::TestJobWithArguments, 1, 2)
    end
    assert_match(/Enqueued ResqueJobs::TestJobWithArguments to Resque\(my_queue\) at .+ with arguments: 1, 2/i, output)
  end

  def test_enqueue_in
    output = capture_logging do
      Resque.enqueue_in(10, ResqueJobs::TestJobWithArguments, 1, 2)
    end
    assert_match(/Enqueued ResqueJobs::TestJobWithArguments to Resque\(default\) at .+ with arguments: 1, 2/i, output)
  end

  def test_enqueue_in_with_queue
    output = capture_logging do
      Resque.enqueue_in_with_queue(:my_queue, 10, ResqueJobs::TestJobWithArguments, 1, 2)
    end
    assert_match(/Enqueued ResqueJobs::TestJobWithArguments to Resque\(my_queue\) at .+ with arguments: 1, 2/i, output)
  end

  def test_logging_in_server_mode
    Resque.enqueue(ResqueJobs::ParentJob)
    out, = capture_subprocess_io do
      start_worker_and_wait
    end
    assert_match(/Enqueued ResqueJobs::TestJobWithArguments .+ with arguments: "from_parent"/i, out)
  end

  private
    def capture_logging
      previous_logger = Resque.logger
      out = StringIO.new
      logger = Logger.new(out)
      Resque.logger = logger
      yield
      out.string
    ensure
      Resque.logger = previous_logger
    end

    def start_worker_and_wait
      pid = spawn("VERBOSE=1 FORK_PER_JOB=false QUEUE=default bundle exec rake resque:work")
    ensure
      Process.wait(pid)
    end
end
