# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

require "resque"
require "resque/tasks"

# Needed for resque integration test.
task :load_resque_jobs do
  require "job_enqueue_logger"
  require_relative "test/support/resque_jobs"
end
Rake::Task["resque:preload"].enhance(["load_resque_jobs"])

task default: :test
