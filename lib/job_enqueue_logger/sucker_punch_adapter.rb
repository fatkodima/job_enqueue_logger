# frozen_string_literal: true

module JobEnqueueLogger
  # There is no easy way to detect if the job is performed inline,
  # so extend only enqueuing methods.
  module SuckerPunchAdapter
    module Job
      def perform_async(*args)
        enqueued = super
        if enqueued
          message = "Enqueued #{name} to SuckerPunch" + Utils.args_info(args)
          Utils.log_job_enqueue(SuckerPunchAdapter.logger, message)
        end
        enqueued
      end
      ruby2_keywords(:perform_async)

      def perform_in(interval, *args)
        enqueued = super
        if enqueued
          at = (Time.now + interval).utc
          message = "Enqueued #{name} to SuckerPunch in #{interval} seconds (at #{at})" + Utils.args_info(args)
          Utils.log_job_enqueue(SuckerPunchAdapter.logger, message)
        end
        enqueued
      end
      ruby2_keywords(:perform_in)
    end

    def self.logger
      JobEnqueueLogger.logger || SuckerPunch.logger
    end
  end
end

SuckerPunch::Job::ClassMethods.prepend(JobEnqueueLogger::SuckerPunchAdapter::Job)
