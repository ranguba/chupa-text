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

      def initialize
        @input = nil
        @configuration = Configuration.default
      end

      def run(*arguments)
        return false unless parse_arguments(arguments)

        Decomposers.load
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
        parser.on("--configuration=FILE",
                  "Read configuration from FILE.") do |path|
          load_configuration(path)
        end
        parser
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
        Formatters::JSON.new($stdout)
      end
    end
  end
end
