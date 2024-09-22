# Copyright (C) 2013-2024  Sutou Kouhei <kou@clear-code.com>
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

require "chupa-text/sax-parser"

module ChupaText
  module Decomposers
    class XML < Decomposer
      include Loggable

      registry.register("xml", self)

      def target?(data)
        data.extension == "xml" or
          data.mime_type == "text/xml"
      end

      def decompose(data)
        text = +""
        listener = Listener.new(text)
        data.open do |input|
          begin
            parser = SAXParser.new(input, listener)
            parser.parse
          rescue SAXParser::ParseError => xml_error
            error do
              message = "#{log_tag} Failed to parse XML: "
              message << "#{xml_error.class}: #{xml_error.message}\n"
              message << xml_error.backtrace.join("\n")
              message
            end
            return
          end
        end
        text_data = TextData.new(text, :source_data => data)
        yield(text_data)
      end

      private
      def log_tag
        "[decomposer][xml]"
      end

      class Listener < SAXListener
        def initialize(output)
          @output = output
          @level = 0
        end

        def start_element(*args)
          @level += 1
        end

        def end_element(*args)
          @level -= 1
        end

        def characters(text)
          @output << text if @level > 0
        end

        def cdata(content)
          @output << content if @level > 0
        end
      end
    end
  end
end
