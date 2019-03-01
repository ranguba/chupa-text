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

require "rexml/document"
require "rexml/streamlistener"

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
        text = ""
        listener = Listener.new(text)
        data.open do |input|
          begin
            parser = REXML::Parsers::StreamParser.new(input, listener)
            parser.parse
          rescue REXML::ParseException => xml_error
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
      class Listener
        include REXML::StreamListener

        def initialize(output)
          @output = output
        end

        def text(text)
          @output << text
        end
      end
    end
  end
end
