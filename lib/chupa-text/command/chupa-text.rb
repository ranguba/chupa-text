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

require "optparse"

module ChupaText
  module Command
    class ChupaText
      class << self
        def run(*arguments)
          chupa_text = new
          chupa_text.run(*arguments)
        end
      end

      AVAILABLE_FORMATS = [:json, :text]

      def initialize
        @input = nil
        @configuration = Configuration.default
        @enable_gems = true
        @format = :json
      end

      def run(*arguments)
        return false unless parse_arguments(arguments)

        load_decomposers
        extractor = create_extractor
        data = create_data
        formatter = create_formatter
        formatter.format_start(data)
        extractor.extract(data) do |extracted|
          formatter.format_extracted(extracted)
        end
        formatter.format_finish(data)
        true
      end

      private
      def load_configuration(path)
        loader = ConfigurationLoader.new(@configuration)
        loader.load(path)
      end

      def parse_arguments(arguments)
        parser = create_option_parser
        rest = nil
        begin
          rest = parser.parse!(arguments)
        rescue OptionParser::ParseError
          puts($!.message)
          return false
        end
        if rest.size > 1
          puts(parser.help)
          return false
        end
        @input, = rest
        true
      end

      def create_option_parser
        parser = OptionParser.new
        parser.banner += " [FILE_OR_URI]"
        parser.version = VERSION

        parser.separator("")
        parser.separator("Generic options")
        parser.on("--configuration=FILE",
                  "Reads configuration from FILE.") do |path|
          load_configuration(path)
        end
        parser.on("--disable-gems",
                  "Disables decomposers installed by RubyGems.") do
          @enable_gems = false
        end
        parser.on("-I=PATH",
                  "Appends PATH to decomposer load path.") do |path|
          $LOAD_PATH << path
        end
        parser.on("--format=FORMAT", AVAILABLE_FORMATS,
                  "Output FORMAT.",
                  "[#{AVAILABLE_FORMATS.join(', ')}]",
                  "(default: json)") do |format|
          format = format.to_sym
          @format = format
        end

        parser.separator("")
        parser.separator("Log related options:")
        parser.on("--log-output=OUTPUT",
                  "Sets log output.",
                  "[-(stdout), +(stderr), PATH]",
                  "(default: +(stderr))") do |output|
          ENV["CHUPA_TEXT_LOG_OUTPUT"] = output
          ::ChupaText.logger = nil
        end
        parser.on("--log-level=LEVEL", available_log_levels,
                  "Sets log level.",
                  "[#{available_log_levels.join(', ')}]",
                  "(default: #{current_log_level_name})") do |level|
          ENV["CHUPA_TEXT_LOG_LEVEL"] = level
          ::ChupaText.logger = nil
        end

        parser
      end

      def available_log_levels
        [
          "debug",
          "info",
          "warn",
          "error",
          "fatal",
          "unknown",
        ]
      end

      def current_log_level_name
        level = ::ChupaText.logger.level
        Logger::Severity.constants.each do |name|
          next if Logger::Severity.const_get(name) != level
          return name.to_s.downcase
        end
        "info"
      end

      def load_decomposers
        Decomposers.enable_all_gems if @enable_gems
        Decomposers.load
      end

      def create_extractor
        extractor = Extractor.new
        extractor.apply_configuration(@configuration)
        extractor
      end

      def create_data
        if @input.nil?
          VirtualFileData.new(nil, $stdin)
        else
          InputData.new(@input)
        end
      end

      def create_formatter
        case @format
        when :json
          Formatters::JSON.new($stdout)
        when :text
          Formatters::Text.new($stdout)
        end
      end
    end
  end
end
