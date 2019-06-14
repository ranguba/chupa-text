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

    @default_timeout = nil
    @default_limit_cpu = nil
    @default_limit_as = nil
    class << self
      def default_timeout
        @default_timeout || ENV["CHUPA_TEXT_EXTERNAL_COMMAND_TIMEOUT"]
      end

      def default_timeout=(timeout)
        @default_timeout = timeout
      end

      def default_limit_cpu
        @default_limit_cpu || limit_env("CPU")
      end

      def default_limit_cpu=(cpu)
        @default_limit_cpu = cpu
      end

      def default_limit_as
        @default_limit_as || limit_env("AS")
      end

      def default_limit_as=(as)
        @default_limit_as = as
      end

      private
      def limit_env(name)
        ENV["CHUPA_TEXT_EXTERNAL_COMMAND_LIMIT_#{name}"] ||
          # For backward compatibility
          ENV["CHUPA_EXTERNAL_COMMAND_LIMIT_#{name}"]
      end
    end

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
      data = options[:data]
      pid = spawn(options[:env] || {},
                  @path.to_s,
                  *arguments,
                  spawn_options(options[:spawn_options], data))
      if data
        soft_timeout = data.timeout
      else
        soft_timeout = nil
      end
      status = nil
      begin
        status = wait_process(pid, options[:timeout], soft_timeout)
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
    def spawn_options(user_options, data)
      options = (user_options || {}).dup
      if data
        soft_limit_cpu = data.limit_cpu
        soft_limit_as = data.limit_as
      else
        soft_limit_cpu = nil
        soft_limit_as = nil
      end
      apply_default_spawn_limit(options, soft_limit_cpu, :cpu, :time)
      apply_default_spawn_limit(options, soft_limit_as, :as, :size)
      options
    end

    def apply_default_spawn_limit(options, soft_value, key, type)
      # TODO: Workaround for Ruby 2.3.3p222
      case key
      when :cpu
        option_key = :rlimit_cpu
        unit = "s"
      when :as
        option_key = :rlimit_as
        unit = ""
      else
        option_key = :"rlimit_#{key}"
        unit = ""
      end
      return if options[option_key]

      tag = "[limit][#{key}]"
      value = self.class.__send__("default_limit_#{key}")
      value = __send__("parse_#{type}", tag, value)
      soft_value = __send__("parse_#{type}", tag, soft_value)
      if value
        value = soft_value if soft_value and soft_value < value
      else
        value = soft_value
      end
      return if value.nil?
      rlimit_number = Process.const_get("RLIMIT_#{key.to_s.upcase}")
      soft_limit, hard_limit = Process.getrlimit(rlimit_number)
      if hard_limit < value
        log_hard_limit_over_value(tag, value, hard_limit)
        return nil
      end
      limit_info = "soft-limit:#{soft_limit}, hard-limit:#{hard_limit}"
      info("#{log_tag}#{tag}[set] <#{value}#{unit}>(#{limit_info})")

      options[option_key] = value
    end

    def log_hard_limit_over_value(tag, value, hard_limit)
      warn("#{log_tag}#{tag}[large] " +
           "<#{value}>(hard-limit:#{hard_limit})")
    end

    def parse_int(tag, value)
      case value
      when nil
        nil
      when Integer
        value
      when Float
        value.round
      else
        return nil if value.empty?
        begin
          Integer(value)
        rescue ArgumentError
          log_invalid_value(tag, value, type, "int")
          nil
        end
      end
    end

    def parse_size(tag, value)
      case value
      when nil
        nil
      when Numeric
        value
      else
        return nil if value.empty?
        scale = 1
        case value
        when /GB?\z/i
          scale = 1000 ** 3
          number = $PREMATCH
        when /GiB?\z/i
          scale = 1024 ** 3
          number = $PREMATCH
        when /MB?\z/i
          scale = 1000 ** 2
          number = $PREMATCH
        when /MiB?\z/i
          scale = 1024 ** 2
          number = $PREMATCH
        when /[kK]B?\z/i
          scale = 1000 ** 1
          number = $PREMATCH
        when /KiB?\z/i
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
    end

    def parse_time(tag, value)
      case value
      when nil
        nil
      when Numeric
        value
      else
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
    end

    def log_invalid_value(tag, value, type)
      super("#{log_tag}#{tag}", value, type)
    end

    def wait_process(pid, timeout, soft_timeout)
      tag = "[timeout]"
      timeout = TimeoutValue.new(tag, timeout || self.class.default_timeout).raw
      soft_timeout = TimeoutValue.new(tag, soft_timeout).raw
      if timeout
        timeout = soft_timeout if soft_timeout and soft_timeout < timeout
      else
        timeout = soft_timeout
      end
      if timeout
        info("#{log_tag}#{tag}[use] " +
             "<#{TimeoutValue.new(tag, timeout)}>: <#{pid}>")
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
