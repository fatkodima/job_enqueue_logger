# frozen_string_literal: true

module JobEnqueueLogger
  module Utils
    def self.log_job_enqueue(logger, message)
      message = "[JobEnqueueLogger] #{message}"
      return logger.info(message) unless JobEnqueueLogger.backtrace

      backtrace = caller
      cleaned_backtrace = JobEnqueueLogger.backtrace_cleaner&.call(backtrace) || backtrace
      lines =
        if JobEnqueueLogger.backtrace == true
          cleaned_backtrace
        else
          cleaned_backtrace[0...JobEnqueueLogger.backtrace.to_i]
        end

      logger.info("#{message}\n↳ #{lines.join("\n  ")}")
    end

    def self.args_info(args)
      if Array(args).any?
        " with arguments: #{Array(args).map(&:inspect).join(', ')}"
      else
        ""
      end
    end
  end
end
