# frozen_string_literal: true

module ResqueJobs
  class TestJob
    @queue = :default
    def self.perform; end
  end

  class TestJobWithArguments
    @queue = :default
    def self.perform(*); end
  end

  class TestJobWithHook
    @queue = :default
    def self.perform; end

    def self.before_enqueue_halt
      false
    end
  end

  class ParentJob
    @queue = :default
    def self.perform
      Resque.enqueue(TestJobWithArguments, "from_parent")
      Process.kill("TERM", Process.pid)
    end
  end
end
