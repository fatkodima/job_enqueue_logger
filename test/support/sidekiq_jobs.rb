# frozen_string_literal: true

module SidekiqJobs
  class TestJob
    include Sidekiq::Job
    def perform; end
  end

  class TestJobWithArguments
    include Sidekiq::Job
    def perform(*); end
  end

  class ParentJob
    include Sidekiq::Job
    def perform
      TestJobWithArguments.perform_async("from_parent")
      Process.kill("TERM", Process.pid)
    end
  end

  class HaltingMiddleware
    def call(*)
      false
    end
  end

  class ConditionallyHaltingMiddleware
    def call(_worker, job, _queue, _redis_pool)
      if job["args"].include?("halt")
        false
      else
        yield
      end
    end
  end
end
