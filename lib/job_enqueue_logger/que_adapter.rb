# frozen_string_literal: true

module JobEnqueueLogger
  module QueAdapter
    module Job
      def enqueue(*)
        job = super
        unless Thread.current[:que_jobs_to_bulk_insert]
          job_attrs = job.que_attrs
          job_class = job_attrs[:job_class]
          args = job_attrs[:args]
          args << job_attrs[:kwargs] unless job_attrs[:kwargs].empty?

          if (id = job_attrs[:id])
            message = "Enqueued #{job_class} (id=#{id}) to Que(#{job_attrs[:queue]})"

            run_at = job_attrs[:run_at].utc
            message += " at #{run_at}" if run_at > Time.now.utc
            message += Utils.args_info(args)
          else
            # Job performed inline.
            message = "Performed inline #{job_class}" + Utils.args_info(args)
          end
          Utils.log_job_enqueue(QueAdapter.logger, message)
        end
        job
      end
      ruby2_keywords(:enqueue)

      def bulk_enqueue(**)
        jobs = super
        if jobs.any?
          job_attrs = jobs.first.que_attrs
          job_class = job_attrs[:job_class]

          if job_attrs[:id]
            run_at = job_attrs[:run_at].utc

            message = "Enqueued"
            message += " #{jobs.size}" if jobs.size > 1
            message += " #{job_class} to Que(#{job_attrs[:queue]})"
            message += " at #{run_at}" if run_at > Time.now.utc
          else
            message = "Performed inline"
            message += " #{jobs.size}" if jobs.size > 1
            message += " #{job_class}"
          end

          Utils.log_job_enqueue(QueAdapter.logger, message)
        end
        jobs
      end
    end

    def self.logger
      # Que.server? is defined in the newest version of Que - https://github.com/que-rb/que/pull/382
      is_server = defined?(Que::CommandLineInterface)

      if !is_server && JobEnqueueLogger.logger
        JobEnqueueLogger.logger
      elsif Que.logger.respond_to?(:call)
        Que.logger.call
      else
        Que.logger
      end
    end
  end
end

Que::Job.singleton_class.prepend(JobEnqueueLogger::QueAdapter::Job)
