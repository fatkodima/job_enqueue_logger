# frozen_string_literal: true

module JobEnqueueLogger
  module DelayedJobAdapter
    module Job
      def enqueue(*args)
        job = super

        # Job with arguments (instance variables of the job) are serialized
        # into yaml. There is no easy way to get them, so just skip logging it.
        if job.persisted?
          message = "Enqueued #{job.name} (id=#{job.id}) to DelayedJob(#{job.queue})"
          message += " at #{job.run_at.utc}" if job.run_at > Delayed::Job.db_time_now
        else
          message = "Performed inline #{job.name}"
        end
        Utils.log_job_enqueue(DelayedJobAdapter.logger, message)

        job
      end
    end

    module Worker
      def start
        # There is no easy way (compared to Sidekiq) to detect
        # if we are in server mode.
        JobEnqueueLogger::DelayedJobAdapter.server = true
        super
      end
    end

    class << self
      attr_accessor :server
      alias server? server

      def logger
        if !server? && defined?(Rails)
          Rails.logger
        else
          Delayed::Worker.logger
        end
      end
    end
  end
end

Delayed::Job.singleton_class.prepend(JobEnqueueLogger::DelayedJobAdapter::Job)
Delayed::Worker.prepend(JobEnqueueLogger::DelayedJobAdapter::Worker)
