# expertiza_logger.rb
# This file contains the formatter used for the ExpertizaLogger and the ExpertizaLogger. 
# ExpertizaLogger provides 5 levels of logging: debug, info, warn, error, and fatal.

# ExpertizaLogFormatter formats the logs to ensure consistent log message formatting. 
class ExpertizaLogFormatter < Logger::Formatter
  # This method is invoked when a log event occurs and formats the message.
  def call(s, ts, pg, msg)
    if msg.is_a?(LoggerMessage)
      "TST=[#{ts}] SVT=[#{s}] PNM=[#{pg}] OIP=[#{msg.oip}] RID=[#{msg.req_id}] CTR=[#{msg.generator}] UID=[#{msg.unity_id}] MSG=[#{filter(msg.message)}]\n"
    else
      "TST=[#{ts}] SVT=[#{s}] PNM=[#{pg}] OIP=[] RID=[] CTR=[] UID=[] MSG=[#{filter(msg)}]\n"
    end
  end

  # Filter out the newline characters in the message and replace with a space character.
  # Reason:
  #   Each log message should be a single-line entry in a log file to ensure they are easily readable and parsable.
  #   The presence of newline characters can break log parsers and make logs harder to analyze.
  def filter(msg)
    msg.tr("\n", ' ')
  end
end

# ExpertizaLogger provides the logging levels and functionality.
# Each level creates its own file (expertiza_info.log or similar) and 
# uses the ExpertizaLogFormatter to format and then print the message.
class ExpertizaLogger

  # Logs an informational message.
  #
  # Use the INFO level to log general application events that confirm things are working as expected.
  def self.info(message = nil)
    @info_log ||= Logger.new(Rails.root.join('log', 'expertiza_info.log'))
    add_formatter @info_log
    @info_log.info(message)
  end

  # Logs a warning message.
  #
  # Use the WARN level to log unexpected events that are not immediately harmful but might cause issues later.
  def self.warn(message = nil)
    @warn_log ||= Logger.new(Rails.root.join('log', 'expertiza_warn.log'))
    add_formatter @warn_log
    @warn_log.warn(message)
  end

  # Logs an error message.
  #
  # Use the ERROR level to log issues that have caused an operation to fail, such as erroneous database requests.
  def self.error(message = nil)
    @error_log ||= Logger.new(Rails.root.join('log', 'expertiza_error.log'))
    add_formatter @error_log
    @error_log.error(message)
  end

  # Logs a fatal message.
  #
  # Use the FATAL level for severe errors that lead to application termination.
  def self.fatal(message = nil)
    @fatal_log ||= Logger.new(Rails.root.join('log', 'expertiza_fatal.log'))
    add_formatter @fatal_log
    @fatal_log.fatal(message)
  end

  # Logs a debug message.
  #
  # Use the DEBUG level for diagnostic information useful during development.
  def self.debug(message = nil)
    @debug_log ||= Logger.new(Rails.root.join('log', 'expertiza_debug.log'))
    add_formatter @debug_log
    @debug_log.debug(message)
  end

  # Adds the custom formatter to the given logger instance.
  # Reason:
  #   Ensures all log messages are consistently formatted using ExpertizaLogFormatter.
  def self.add_formatter(log)
    log.formatter ||= ExpertizaLogFormatter.new
  end
end