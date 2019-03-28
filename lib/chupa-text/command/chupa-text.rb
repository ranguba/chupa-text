# Copyright (C) 2013-2019  Kouhei Sutou <kou@clear-code.com>
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

      AVAILABLE_FORMATS = [:json, :text, :mime]

      SIZE = /\A\d+x\d+\z/o
      OptionParser.accept(SIZE, SIZE) do |value|
        if value
          begin
            value.split("x").collect {|number| Integer(number)}
          rescue ArgumentError
            raise OptionParser::InvalidArgument, value
          end
        end
      end

      def initialize
        @input = nil
        @configuration = Configuration.load_default
        @enable_gems = true
        @uri = nil
        @mime_type = nil
        @format = :json
        @mime_formatter_options = {}
        @need_screenshot = true
        @expected_screenshot_size = [200, 200]
        @max_body_size = nil
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

        parser.separator("")
        parser.separator("Input related options")
        parser.on("--uri=URI",
                  "Input data URI.") do |uri|
          @uri = URI.parse(uri)
        end
        parser.on("--mime-type=MIME_TYPE",
                  "Input data MIME type.") do |mime_type|
          @mime_type = mime_type
        end

        parser.separator("")
        parser.separator("Output related options")
        parser.on("--format=FORMAT", AVAILABLE_FORMATS,
                  "Output FORMAT.",
                  "[#{AVAILABLE_FORMATS.join(', ')}]",
                  "(default: #{@format})") do |format|
          @format = format
        end
        parser.on("--mime-boundary=BOUNDARY",
                  "Use BOUNDARY for MIME boundary.",
                  "(default: Use SHA1 digest of URI)") do |boundary|
          @mime_formatter_options[:boundary] = boundary
        end
        parser.on("--[no-]need-screenshot",
                  "Generate screenshot if available.",
                  "(default: #{@need_screenshot})") do |boolean|
          @need_screenshot = boolean
        end
        parser.on("--expected-screenshot-size=WIDTHxHEIGHT", SIZE,
                  "Expected screenshot size.",
                  "(default: #{@expected_screenshot_size.join("x")})") do |size|
          @expected_screenshot_size = size
        end
        parser.on("--max-body-size=BYTE", Integer,
                  "The max byte of extracted body.",
                  "(default: no limit)") do |size|
          @max_body_size = size
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
          data = VirtualFileData.new(@uri, $stdin)
        else
          case @input
          when /\A[a-z]+:\/\//i
            input = URI.parse(@input)
          else
            input = Pathname(@input)
          end
          if @uri
            input.open("rb") do |io|
              data = VirtualFileData.new(@uri, io)
            end
          else
            data = InputData.new(input)
          end
        end
        data.mime_type = @mime_type if @mime_type
        data.need_screenshot = @need_screenshot
        data.expected_screenshot_size = @expected_screenshot_size
        data.max_body_size = @max_body_size
        data
      end

      def create_formatter
        case @format
        when :json
          Formatters::JSON.new($stdout)
        when :text
          Formatters::Text.new($stdout)
        when :mime
          Formatters::MIME.new($stdout, @mime_formatter_options)
        end
      end
    end
  end
end
