# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/que_jobs"

class QueAdapterTest < TestCase
  def setup
    super
    Que.clear!
  end

  def test_enqueue
    job = nil
    output = capture_logging do
      job = QueJobs::TestJob.enqueue
      assert job.que_attrs[:id]
    end
    assert_match("Enqueued QueJobs::TestJob (id=#{job.que_attrs[:id]}) to Que(default)", output)
  end

  def test_enqueue_with_arguments
    output = capture_logging do
      QueJobs::TestJobWithArguments.enqueue(1, 2)
    end
    assert_match(" with arguments: 1, 2", output)
  end

  def test_enqueue_with_kwargs
    output = capture_logging do
      QueJobs::TestJobWithKwargs.enqueue(1, 2, key: "value")
    end
    assert_match(' with arguments: 1, 2, {:key=>"value"}', output)
  end

  def test_enqueue_with_custom_queue
    output = capture_logging do
      QueJobs::TestJobWithArguments.enqueue(1, job_options: { queue: "my_queue" })
    end
    assert_match(/to Que\(my_queue\) with arguments: 1$/, output)
  end

  def test_enqueue_scheduling
    output = capture_logging do
      QueJobs::TestJob.enqueue(job_options: { run_at: Time.now + 10 })
    end
    assert_match(/Enqueued QueJobs::TestJob \(id=\w+\) to Que\(default\) at .+/i, output)
  end

  def test_enqueue_when_running_synchronously
    run_synchronously do
      output = capture_logging do
        job = QueJobs::TestJobWithArguments.enqueue(1)
        assert_nil job.que_attrs[:id]
      end
      assert_match("Performed inline QueJobs::TestJobWithArguments with arguments: 1", output)
    end
  end

  def test_enqueue_scheduling_when_running_synchronously
    run_synchronously do
      output = capture_logging do
        QueJobs::TestJob.enqueue(job_options: { run_at: Time.now + 10 })
      end
      assert_match(/Enqueued QueJobs::TestJob \(id=\w+\) to Que\(default\) at .+/i, output)
    end
  end

  def test_bulk_enqueue
    output = capture_logging do
      jobs = Que.bulk_enqueue do
        QueJobs::TestJob.enqueue
        QueJobs::TestJob.enqueue
      end
      assert_equal 2, jobs.size
      assert jobs.first.que_attrs[:id]
    end
    assert_match("Enqueued 2 QueJobs::TestJob to Que(default)", output)

    # There should be no logs for inner jobs enqueuing.
    assert_not_match("Enqueued QueJobs::TestJob", output)
  end

  def test_bulk_enqueue_none
    output = capture_logging do
      jobs = Que.bulk_enqueue do
        # noop
      end
      assert_empty jobs
    end
    assert_empty output
  end

  def test_bulk_enqueue_single_item
    output = capture_logging do
      Que.bulk_enqueue do
        QueJobs::TestJob.enqueue
      end
    end
    assert_match("Enqueued QueJobs::TestJob to Que(default)", output)
  end

  def test_bulk_enqueue_with_custom_queue
    output = capture_logging do
      Que.bulk_enqueue(job_options: { queue: "my_queue" }) do
        QueJobs::TestJob.enqueue
        QueJobs::TestJob.enqueue
      end
    end
    assert_match("Enqueued 2 QueJobs::TestJob to Que(my_queue)", output)
  end

  def test_bulk_enqueue_scheduling
    output = capture_logging do
      Que.bulk_enqueue(job_options: { run_at: Time.now + 10 }) do
        QueJobs::TestJob.enqueue
        QueJobs::TestJob.enqueue
      end
    end
    assert_match(/Enqueued 2 QueJobs::TestJob to Que\(default\) at .+/i, output)
  end

  def test_bulk_enqueue_when_running_synchronously
    run_synchronously do
      output = capture_logging do
        Que.bulk_enqueue do
          QueJobs::TestJob.enqueue
          QueJobs::TestJob.enqueue
        end
      end
      assert_match("Performed inline 2 QueJobs::TestJob", output)
    end
  end

  def test_logging_in_server_mode
    out, = capture_subprocess_io do
      QueJobs::ParentJob.enqueue
      start_worker_and_wait
    end
    assert_match(/Enqueued QueJobs::TestJobWithArguments .+ with arguments: "from_parent"/i, out)
  end

  private
    def capture_logging(&block)
      out = StringIO.new
      logger = Logger.new(out)
      Que.stub(:logger, logger, &block)
      out.string
    end

    def run_synchronously
      Que.run_synchronously = true
      yield
    ensure
      Que.run_synchronously = false
    end

    def start_worker_and_wait
      pid = spawn("bundle exec que --worker-count 1 ./test/que_adapter_test.rb")
    ensure
      Process.wait(pid)
    end
end
