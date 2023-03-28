# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"
require "rubocop/rake_task"

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

require "delayed_job"
require "delayed_job_active_record"
require "delayed/tasks"

# Needed for delayed_job integration test.
task :environment # noop

task :load_delayed_job_jobs do
  require "job_enqueue_logger"
  require_relative "test/support/delayed_job_jobs"

  require "logger"
  Delayed::Worker.logger = Logger.new($stdout)

  ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: "test/test_db.sqlite3")
end
Rake::Task["jobs:workoff"].enhance(["load_delayed_job_jobs"])

RuboCop::RakeTask.new

task default: [:rubocop, :test]
