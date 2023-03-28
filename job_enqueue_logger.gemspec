# frozen_string_literal: true

require_relative "lib/job_enqueue_logger/version"

Gem::Specification.new do |spec|
  spec.name = "job_enqueue_logger"
  spec.version = JobEnqueueLogger::VERSION
  spec.authors = ["fatkodima"]
  spec.email = ["fatkodima123@gmail.com"]

  spec.summary = "Log background jobs enqueued by your application (additionally with backtraces)."
  spec.description = "Log background jobs enqueued by your application (additionally with backtraces).
                      Helps with debugging, or just generally understanding what's going on under the hood.
                      Useful for finding where to start when making changes to a large application."
  spec.homepage = "https://github.com/fatkodima/job_enqueue_logger"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/master/CHANGELOG.md"

  spec.files = Dir["*.{md,txt}", "lib/**/*"]
  spec.require_paths = ["lib"]
end
