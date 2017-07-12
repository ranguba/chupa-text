# Copyright (C) 2014  Kouhei Sutou <kou@clear-code.com>
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
      spawn_options = options[:spawn_options] || {}
      pid = spawn(options[:env] || {},
                  @path.to_s,
                  *arguments,
                  default_spawn_options.merge(spawn_options))
      pid, status = Process.waitpid2(pid)
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
    def default_spawn_options
      SpawnLimitOptions.new.options
    end

    class SpawnLimitOptions
      include Loggable

      attr_reader :options
      def initialize
        @options = {}
        set_default_options
      end

      private
      def set_default_options
        set_option(:cpu, :int)
        set_option(:rss, :size)
        set_option(:as, :size)
      end

      def set_option(key, type)
        value =
          ENV["CHUPA_TEXT_EXTERNAL_COMMAND_LIMIT_#{key.to_s.upcase}"] ||
          # For backward compatibility
          ENV["CHUPA_EXTERNAL_COMMAND_LIMIT_#{key.to_s.upcase}"]
        return if value.nil?
        value = send("parse_#{type}", key, value)
        return if value.nil?
        rlimit_number = Process.const_get("RLIMIT_#{key.to_s.upcase}")
        soft_limit, hard_limit = Process.getrlimit(rlimit_number)
        if hard_limit < value
          log_hard_limit_over_value(key, value, hard_limit)
          return nil
        end
        limit_info = "soft-limit:#{soft_limit}, hard-limit:#{hard_limit}"
        info("#{log_tag}[#{key}][set] <#{value}>(#{limit_info})")

        # TODO: Workaround for Ruby 2.3.3p222
        case key
        when :cpu
          @options[:rlimit_cpu] = value
        when :rss
          @options[:rlimit_rss] = value
        when :as
          @options[:rlimit_as] = value
        else
          @options[:"rlimit_#{key}"] = value
        end
      end

      def parse_int(key, value)
        begin
          Integer(value)
        rescue ArgumentError
          log_invalid_value(key, value, type, "int")
          nil
        end
      end

      def parse_size(key, value)
        return nil if value.nil?
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
          log_invalid_value(key, value, "size")
          return nil
        end
        (number * scale).to_i
      end

      def log_hard_limit_over_value(key, value, hard_limit)
        warn("#{log_tag}[#{key}][large] <#{value}>(hard-limit:#{hard_limit})")
      end

      def log_invalid_value(key, value, type)
        warn("#{log_tag}[#{key}][invalid] <#{value}>(#{type})")
      end

      def log_tag
        "[external-command][limit]"
      end
    end
  end
end
