# frozen_string_literal: true

module JobEnqueueLogger
  module ResqueAdapter
    module Enqueuing
      def enqueue_to(queue, klass, *args)
        enqueued = super
        if enqueued
          message =
            if Resque.inline?
              "Performed inline #{klass}" + Utils.args_info(args)
            else
              "Enqueued #{klass} to Resque(#{queue})" + Utils.args_info(args)
            end
          Utils.log_job_enqueue(ResqueAdapter.logger, message)
        end
        enqueued
      end
    end

    module DelayedEnqueuing
      def delayed_push(timestamp, item)
        super
        message = "Enqueued #{item[:class]} to Resque(#{item[:queue]}) at #{timestamp.utc}" +
                  Utils.args_info(item[:args])
        Utils.log_job_enqueue(ResqueAdapter.logger, message)
      end
    end

    module Worker
      def work(*)
        # There is no easy way (compared to Sidekiq) to detect
        # if we are in server mode.
        JobEnqueueLogger::ResqueAdapter.server = true
        super
      end
    end

    class << self
      attr_accessor :server
      alias server? server

      def logger
        if !server? && JobEnqueueLogger.logger
          JobEnqueueLogger.logger
        else
          Resque.logger
        end
      end
    end
  end
end

Resque.singleton_class.prepend(JobEnqueueLogger::ResqueAdapter::Enqueuing)
Resque::Worker.prepend(JobEnqueueLogger::ResqueAdapter::Worker)

begin
  require "resque-scheduler"
  Resque.singleton_class.prepend(JobEnqueueLogger::ResqueAdapter::DelayedEnqueuing)
rescue LoadError
  # scheduling gem is not available
end
