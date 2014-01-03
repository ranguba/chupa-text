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
require "uri"
require "open-uri"

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
        @configuration = Configuration.new
      end

      def run(*arguments)
        return false unless parse_arguments(arguments)

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
          loader = ConfigurationLoader.new(@configuration)
          loader.load(path)
        end
        parser
      end

      def create_extractor
        Decomposers.load
        extractor = Extractor.new
        decomposers = Decomposers.create(Decomposer.registry,
                                         @configuration.decomposer)
        decomposers.each do |decomposer|
          extractor.add_decomposer(decomposer)
        end
        extractor
      end

      def create_data
        data = Data.new
        if @input.nil?
          data.body = $stdin.read
        else
          uri = URI.parse(@input)
          if uri.is_a?(URI::HTTP)
            open(uri) do |input|
              data.body = input.read
              data.content_type = input.content_type
            end
            data["uri"] = @input
          else
            data.path = @input
          end
        end
        data
      end

      def create_formatter
        Formatters::JSON.new($stdout)
      end
    end
  end
end
