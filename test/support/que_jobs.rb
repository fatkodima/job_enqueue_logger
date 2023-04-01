# frozen_string_literal: true

module QueJobs
  class TestJob < Que::Job
    def run; end
  end

  class TestJobWithArguments < Que::Job
    def run(*); end
  end

  class TestJobWithKwargs < Que::Job
    def run(*_args, **_kwargs); end
  end

  class ParentJob < Que::Job
    def run
      TestJobWithArguments.enqueue("from_parent")
      Process.kill("TERM", Process.pid)
    end
  end
end
