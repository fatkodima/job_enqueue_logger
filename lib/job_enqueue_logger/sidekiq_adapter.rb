# frozen_string_literal: true

module JobEnqueueLogger
  module SidekiqAdapter
    module Job
      module Setter
        def perform_inline(*args)
          performed = super
          if performed
            message = "Performed inline #{@klass}" + Utils.args_info(args)
            Utils.log_job_enqueue(SidekiqAdapter.logger, message)
          end
          performed
        end
        alias perform_sync perform_inline
      end
    end

    module Client
      def push(item)
        jid = super(item)
        if jid
          queue = item["queue"] || "default"

          message = "Enqueued #{item['class']} (jid=#{jid}) to Sidekiq(#{queue})"
          message += " at #{Time.at(item['at']).utc}" if item.key?("at")
          message += Utils.args_info(item["args"])

          Utils.log_job_enqueue(SidekiqAdapter.logger, message)
        end
        jid
      end

      def push_bulk(items)
        jids = super(items)
        real_jids = jids.compact
        if real_jids.any?
          queue = items["queue"] || "default"
          message = "Enqueued"
          message += " #{real_jids.size}" if real_jids.size > 1
          message += " #{items['class']} to Sidekiq(#{queue})"

          Utils.log_job_enqueue(SidekiqAdapter.logger, message)
        end
        jids
      end
    end

    def self.logger
      if !Sidekiq.server? && defined?(Rails)
        Rails.logger
      else
        Sidekiq.logger
      end
    end
  end
end

Sidekiq::Job::Setter.prepend(JobEnqueueLogger::SidekiqAdapter::Job::Setter)
Sidekiq::Client.prepend(JobEnqueueLogger::SidekiqAdapter::Client)
