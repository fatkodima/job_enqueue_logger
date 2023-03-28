# frozen_string_literal: true

module DelayedJobJobs
  class TestJob
    def perform; end
  end

  class ParentJob
    def perform
      Delayed::Job.enqueue(TestJob.new)
    end
  end
end
