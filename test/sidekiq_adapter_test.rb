# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/sidekiq_jobs"

class SidekiqAdapterTest < Minitest::Test
  def setup
    Sidekiq.redis(&:flushdb)
  end

  def test_perform_async
    output = capture_logging do
      jid = SidekiqJobs::TestJob.perform_async
      assert_jid(jid)
    end
    assert_match(/Enqueued SidekiqJobs::TestJob \(jid=\w+\) to Sidekiq\(default\)/i, output)
  end

  def test_perform_async_with_arguments
    output = capture_logging { SidekiqJobs::TestJobWithArguments.perform_async(1, 2) }
    assert_match(" with arguments: 1, 2", output)
  end

  def test_perform_async_custom_queue
    output = capture_logging { SidekiqJobs::TestJob.set(queue: :my_queue).perform_async }
    assert_match("to Sidekiq(my_queue)", output)
  end

  def test_perform_async_halted_by_middleware
    with_halting_middleware do
      output = capture_logging do
        jid = SidekiqJobs::TestJob.perform_async
        assert_nil jid
      end
      assert_empty output
    end
  end

  def test_perform_inline
    output = capture_logging do
      performed = SidekiqJobs::TestJob.perform_inline
      assert_equal true, performed
    end
    assert_match "Performed inline SidekiqJobs::TestJob", output
  end

  # `perform_sync` is an alias for `perform_inline`
  def test_perform_sync
    output = capture_logging do
      performed = SidekiqJobs::TestJob.perform_sync
      assert_equal true, performed
    end
    assert_match "Performed inline SidekiqJobs::TestJob", output
  end

  def test_perform_inline_with_arguments
    output = capture_logging { SidekiqJobs::TestJobWithArguments.perform_inline(1, 2) }
    assert_match(" with arguments: 1, 2", output)
  end

  def test_perform_inline_halted_by_middleware
    with_halting_middleware do
      output = capture_logging do
        performed = SidekiqJobs::TestJob.perform_inline
        assert_nil performed
      end
      assert_empty output
    end
  end

  def test_perform_in
    output = capture_logging do
      jid = SidekiqJobs::TestJob.perform_in(10)
      assert_jid(jid)
    end
    assert_match(/Enqueued SidekiqJobs::TestJob \(jid=\w+\) to Sidekiq\(default\) at .+/i, output)
  end

  # `perform_at` is an alias for `perform_in`
  def test_perform_at
    output = capture_logging do
      jid = SidekiqJobs::TestJob.perform_at(10)
      assert_jid(jid)
    end
    assert_match(/Enqueued SidekiqJobs::TestJob \(jid=\w+\) to Sidekiq\(default\) at .+/i, output)
  end

  def test_perform_in_with_arguments
    output = capture_logging { SidekiqJobs::TestJobWithArguments.perform_in(10, 1, 2) }
    assert_match(" with arguments: 1, 2", output)
  end

  def test_perform_in_custom_queue
    output = capture_logging { SidekiqJobs::TestJob.set(queue: :my_queue).perform_in(10) }
    assert_match("to Sidekiq(my_queue)", output)
  end

  def test_perform_in_halted_by_middleware
    with_halting_middleware do
      output = capture_logging do
        performed = SidekiqJobs::TestJob.perform_in(10)
        assert_nil performed
      end
      assert_empty output
    end
  end

  def test_perform_bulk
    output = capture_logging do
      jids = SidekiqJobs::TestJobWithArguments.perform_bulk([[1, 2], [3, 4], [5, 6]])
      assert_equal 3, jids.size
      jids.each { |jid| assert_jid(jid) }
    end
    assert_match "Enqueued 3 SidekiqJobs::TestJobWithArguments to Sidekiq(default)", output
  end

  def test_perform_bulk_single_item
    output = capture_logging { SidekiqJobs::TestJobWithArguments.perform_bulk([[1, 2]]) }
    assert_match "Enqueued SidekiqJobs::TestJobWithArguments to Sidekiq(default)", output
  end

  def test_perform_bulk_custom_queue
    output = capture_logging { SidekiqJobs::TestJobWithArguments.set(queue: :my_queue).perform_bulk([[1, 2]]) }
    assert_match "Sidekiq(my_queue)", output
  end

  def test_perform_bulk_halted_by_middleware
    with_halting_middleware(SidekiqJobs::ConditionallyHaltingMiddleware) do
      output = capture_logging do
        jids = SidekiqJobs::TestJobWithArguments.perform_bulk([[1, 2], [3, "halt"], [4, 5]])
        # Sidekiq 7.1+ started to return nils for not pushed jobs -
        # https://github.com/sidekiq/sidekiq/pull/5766.
        if Gem::Version.new(Sidekiq::VERSION) >= Gem::Version.new("7.1")
          assert_equal 3, jids.size
          assert_nil jids[1]
        else
          assert_equal 2, jids.size
        end
      end
      assert_match "Enqueued 2 SidekiqJobs::TestJobWithArguments to Sidekiq(default)", output
    end
  end

  def test_push_bulk
    output = capture_logging do
      jids = Sidekiq::Client.push_bulk("class" => SidekiqJobs::TestJobWithArguments,
                                       "args" => [[1, 2], [3, 4]], "queue" => "my_queue")
      assert_equal 2, jids.size
      jids.each { |jid| assert_jid(jid) }
    end
    assert_match "Enqueued 2 SidekiqJobs::TestJobWithArguments to Sidekiq(my_queue)", output
  end

  def test_logging_in_server_mode
    SidekiqJobs::ParentJob.perform_async
    out, = capture_subprocess_io do
      start_worker_and_wait
    end
    assert_match(/Enqueued SidekiqJobs::TestJobWithArguments .+ with arguments: "from_parent"/i, out)
  end

  private
    def capture_logging(&block)
      out = StringIO.new
      logger = Logger.new(out)
      logger.level = Sidekiq.logger.level
      Sidekiq.stub(:logger, logger, &block)
      out.string
    end

    def assert_jid(value)
      assert_match(/\w+/, value)
    end

    def with_halting_middleware(middleware = SidekiqJobs::HaltingMiddleware)
      Sidekiq.configure_client do |config|
        config.client_middleware do |chain|
          chain.add(middleware)
        end
      end

      yield
    ensure
      Sidekiq.configure_client do |config|
        config.client_middleware do |chain|
          chain.remove(middleware)
        end
      end
    end

    def start_worker_and_wait
      pid = spawn("bundle exec sidekiq -r ./test/sidekiq_adapter_test.rb -c 1")
    ensure
      Process.wait(pid)
    end
end
