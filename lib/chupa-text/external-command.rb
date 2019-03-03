# Copyright (C) 2014-2019  Kouhei Sutou <kou@clear-code.com>
# Copyright (C) 2010  Yuto HAYAMIZU <y.hayamizu@gmail.com>
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

require "English"
require "pathname"

module ChupaText
  class ExternalCommand
    include Loggable

    attr_reader :path
    def initialize(path)
      @path = Pathname.new(path)
    end

    def run(*arguments)
      if arguments.last.is_a?(Hash)
        options = arguments.pop
      else
        options = {}
      end
      pid = spawn(options[:env] || {},
                  @path.to_s,
                  *arguments,
                  spawn_options(options[:spawn_options]))
      status = nil
      begin
        status = wait_process(pid, options[:timeout])
      ensure
        unless status
          begin
            Process.kill(:KILL, pid)
            Process.waitpid(pid)
          rescue SystemCallError
          end
        end
      end
      status.success?
    end

    def exist?
      if @path.absolute?
        @path.file? and @path.executable?
      else
        (ENV['PATH'] || "").split(File::PATH_SEPARATOR).any? do |path|
          (Pathname.new(path) + @path).expand_path.exist?
        end
      end
    end

    private
    def spawn_options(user_options)
      options = (user_options || {}).dup
      apply_default_spawn_limit(options, :cpu, :int)
      apply_default_spawn_limit(options, :as, :size)
      options
    end

    def apply_default_spawn_limit(options, key, type)
      # TODO: Workaround for Ruby 2.3.3p222
      case key
      when :cpu
        option_key = :rlimit_cpu
      when :as
        option_key = :rlimit_as
      else
        option_key = :"rlimit_#{key}"
      end
      return if options[option_key]

      tag = "[limit][#{key}]"
      value =
        ENV["CHUPA_TEXT_EXTERNAL_COMMAND_LIMIT_#{key.to_s.upcase}"] ||
        # For backward compatibility
        ENV["CHUPA_EXTERNAL_COMMAND_LIMIT_#{key.to_s.upcase}"]
      value = send("parse_#{type}", tag, value)
      return if value.nil?
      rlimit_number = Process.const_get("RLIMIT_#{key.to_s.upcase}")
      soft_limit, hard_limit = Process.getrlimit(rlimit_number)
      if hard_limit < value
        log_hard_limit_over_value(tag, value, hard_limit)
        return nil
      end
      limit_info = "soft-limit:#{soft_limit}, hard-limit:#{hard_limit}"
      info("#{log_tag}#{tag}[set] <#{value}>(#{limit_info})")

      options[option_key] = value
    end

    def log_hard_limit_over_value(tag, value, hard_limit)
      warn("#{log_tag}#{tag}[large] " +
           "<#{value}>(hard-limit:#{hard_limit})")
    end

    def parse_int(tag, value)
      return nil if value.nil?
      return nil if value.empty?
      begin
        Integer(value)
      rescue ArgumentError
        log_invalid_value(tag, value, type, "int")
        nil
      end
    end

    def parse_size(tag, value)
      return nil if value.nil?
      return nil if value.empty?
      scale = 1
      case value
      when /GB?\z/i
        scale = 1024 ** 3
        number = $PREMATCH
      when /MB?\z/i
        scale = 1024 ** 2
        number = $PREMATCH
      when /KB?\z/i
        scale = 1024 ** 1
        number = $PREMATCH
      when /B?\z/i
        number = $PREMATCH
      else
        number = value
      end
      begin
        number = Float(number)
      rescue ArgumentError
        log_invalid_value(tag, value, "size")
        return nil
      end
      (number * scale).to_i
    end

    def parse_time(tag, value)
      return nil if value.nil?
      return nil if value.empty?
      scale = 1
      case value
      when /h\z/i
        scale = 60 * 60
        number = $PREMATCH
      when /m\z/i
        scale = 60
        number = $PREMATCH
      when /s\z/i
        number = $PREMATCH
      else
        number = value
      end
      begin
        number = Float(number)
      rescue ArgumentError
        log_invalid_value(tag, value, "time")
        return nil
      end
      (number * scale).to_f
    end

    def log_invalid_value(tag, value, type)
      warn("#{log_tag}#{tag}[invalid] <#{value}>(#{type})")
    end

    def wait_process(pid, timeout)
      tag = "[timeout]"

      if timeout.nil?
        timeout_env = ENV["CHUPA_TEXT_EXTERNAL_COMMAND_TIMEOUT"]
        timeout = parse_time(tag, timeout_env) if timeout_env
      end

      if timeout
        info("#{log_tag}#{tag}[use] <#{timeout}s>: <#{pid}>")
        status = wait_process_timeout(pid, timeout)
        return status if status
        info("#{log_tag}#{tag}[terminate] <#{pid}>")
        Process.kill(:TERM, pid)
        status = wait_process_timeout(pid, 5)
        return status if status
        info("#{log_tag}#{tag}[kill] <#{pid}>")
        Process.kill(:KILL, pid)
      end
      _, status = Process.waitpid2(pid)
      status
    end

    def wait_process_timeout(pid, timeout)
      limit = Time.now + timeout
      while Time.now < limit
        _, status = Process.waitpid2(pid, Process::WNOHANG)
        return status if status
        sleep(1)
      end
      nil
    end

    def log_tag
      "[external-command]"
    end
  end
end
