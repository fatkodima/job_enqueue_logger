# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/delayed_job_jobs"

class DelayedJobAdapterTest < TestCase
  def test_enqueue
    job = nil
    output = capture_logging do
      job = Delayed::Job.enqueue(DelayedJobJobs::TestJob.new)
    end
    assert job.persisted?
    assert_match("Enqueued DelayedJobJobs::TestJob (id=#{job.id}) to DelayedJob(default)", output)
  end

  def test_enqueue_custom_queue
    job = nil
    output = capture_logging do
      job = Delayed::Job.enqueue(DelayedJobJobs::TestJob.new, queue: "my_queue")
    end
    assert job.persisted?
    assert_match("Enqueued DelayedJobJobs::TestJob (id=#{job.id}) to DelayedJob(my_queue)", output)
  end

  def test_enqueue_when_delayed_is_disabled
    Delayed::Worker.delay_jobs = false

    job = nil
    output = capture_logging do
      job = Delayed::Job.enqueue(DelayedJobJobs::TestJob.new)
    end
    assert_not job.persisted?
    assert_match("Performed inline DelayedJobJobs::TestJob", output)
  ensure
    Delayed::Worker.delay_jobs = true
  end

  def test_enqueue_scheduling
    job = nil
    output = capture_logging do
      job = Delayed::Job.enqueue(DelayedJobJobs::TestJob.new, run_at: Time.now + 10)
    end
    assert job.persisted?
    assert_match(/Enqueued DelayedJobJobs::TestJob \(id=#{job.id}\) to DelayedJob\(default\) at .+/i, output)
  end

  def test_logging_in_server_mode
    capture_logging do
      Delayed::Job.enqueue(DelayedJobJobs::ParentJob.new)
    end
    out, = capture_subprocess_io do
      start_worker_and_wait
    end
    assert_match("Enqueued DelayedJobJobs::TestJob", out)
  end

  private
    def capture_logging
      previous_logger = Delayed::Worker.logger
      out = StringIO.new
      logger = Logger.new(out)
      Delayed::Worker.logger = logger
      yield
      out.string
    ensure
      Delayed::Worker.logger = previous_logger
    end

    def start_worker_and_wait
      pid = spawn("bundle exec rake jobs:workoff")
    ensure
      Process.wait(pid)
    end
end
