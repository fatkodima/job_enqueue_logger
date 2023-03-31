# frozen_string_literal: true

module SuckerPunchJobs
  class TestJob
    include SuckerPunch::Job
    def perform; end
  end

  class TestJobWithArguments
    include SuckerPunch::Job
    def perform(*); end
  end

  class ParentJob
    include SuckerPunch::Job
    def perform
      TestJobWithArguments.perform_async("from_parent")
    end
  end
end
