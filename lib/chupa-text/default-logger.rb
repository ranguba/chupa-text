# Copyright (C) 2013  Kouhei Sutou <kou@clear-code.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

require "logger"

module ChupaText
  # The default logger for ChupaText. Logger options are retrieved from
  # environment variables.
  #
  # Here are environment variables to be used:
  #
  # ## `CHUPA_TEXT_LOG_OUTPUT`
  #
  # It specifies log output.
  #
  #   * `-`: ChupaText outputs to the standard output.
  #   * `+`: ChupaText outputs to the standard error output.
  #   * Others: It is used as file name. ChupaText outputs to the file.
  #
  # The default is `+` (the standard error).
  #
  # ## `CHUPA_TEXT_LOG_ROTATION_PERIOD`
  #
  # It specifies log rotation period.
  #
  # It is ignored when `CHUPA_TEXT_LOG_OUTPUT` is `-` (the standard
  # output) or `+` (the standard error output).
  #
  #   * `daily`: Log file is rotated daily.
  #   * `weekly`: Log file is rotated weekly.
  #   * `monthly`: Log file is rotated monthly.
  #   * Others: Invalid value. It is ignored.
  #
  # ## `CHUPA_TEXT_LOG_N_GENERATIONS`
  #
  # It specifies how many old log files are kept.
  #
  #  It is ignored when (a) `CHUPA_TEXT_LOG_OUTPUT` is `-` (the
  # standard output) or `+` (the standard error output) or (b)
  # `CHUPA_TEXT_LOG_RATATION_PERIOD` is valid value.
  #
  # The default value is `7`.
  #
  # ## `CHUPA_TEXT_LOG_LEVEL`
  #
  # It specifies log verbosity.
  #
  # The default value is `info`.
  #
  #   * `unknown`: ChupaText outputs only unknown messages.
  #   * `fatal`: ChupaText outputs `unknown` level messages and
  #     unhandleable error messages.
  #   * `error`: ChupaText outputs `fatal` level messages and
  #     handleable error messages.
  #   * `warn`: ChupaText outputs `error` level messages and warning
  #      level messages.
  #   * `info`: ChupaText outputs `warn` level messages and generic useful
  #     information messages.
  #   * `debug`: ChupaText outputs all messages.
  class DefaultLogger < Logger
    def initialize
      super(output_device, default_shift_age, default_shift_size)
      self.level = default_level
      self.formatter = Formatter.new
    end

    private
    def output_device
      output = ENV["CHUPA_TEXT_LOG_OUTPUT"] || "+"
      case output
      when "-"
        STDOUT
      when "+"
        STDERR
      else
        output
      end
    end

    def default_shift_age
      rotation_period = ENV["CHUPA_TEXT_LOG_ROTATION_PERIOD"]
      case rotation_period
      when "daily", "weekly", "monthly"
        return rotation_period
      end

      n_generations = ENV["CHUPA_TEXT_LOG_N_GENERATIONS"] || "7"
      begin
        Integer(n_generations)
      rescue ArgumentError
        nil
      end
    end

    def default_shift_size
      max_size = ENV["CHUPA_TEXT_LOG_MAX_SIZE"] || "1MB"
      begin
        SizeParser.parse(max_size)
      rescue SizeParser::InvalidSizeError
        nil
      end
    end

    def default_level
      level_name = (ENV["CHUPA_TEXT_LOG_LEVEL"] || "info").upcase
      if Logger::Severity.const_defined?(level_name)
        Logger::Severity.const_get(level_name)
      else
        Logger::Severity::INFO
      end
    end

    class Formatter
      def call(severity, time, program_name, message)
        "%s: [%d] %s: %s" % [
          time.iso8601(6),
          Process.pid,
          severity[0, 1],
          format_message(message),
        ]
      end

      private
      def format_message(message)
        case message
        when String
          if message.end_with?("\n")
            message
          else
            "#{message}\n"
          end
        when Exception
          "#{message.message}(#{message.class})\n" +
            (message.backtrace || []).join("\n")
        else
          message.inpsect
        end
      end
    end
  end
end
