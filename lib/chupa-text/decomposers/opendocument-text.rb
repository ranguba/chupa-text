# Copyright (C) 2019  Kouhei Sutou <kou@clear-code.com>
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

require "chupa-text/decomposers/opendocument"

module ChupaText
  module Decomposers
    class OpenDocumentText < OpenDocument
      registry.register("opendocument-text", self)

      def initialize(options={})
        super
        @extension = "odt"
        @mime_type = "application/vnd.oasis.opendocument.text"
      end

      private
      def process_content(entry, context, &block)
        context[:text] = ""
        listener = TextListener.new(context[:text])
        parse(entry.file_data, listener)
      end

      def finish_decompose(context, &block)
        text_data = TextData.new(context[:text] || "",
                                 source_data: context[:data])
        context[:attributes].each do |name, value|
          text_data[name] = value
        end
        yield(text_data)
      end

      class TextListener
        include REXML::SAX2Listener

        TEXT_URI = "urn:oasis:names:tc:opendocument:xmlns:text:1.0"
        def initialize(output)
          @output = output
          @in_p = false
        end

        def start_element(uri, local_name, qname, attributes)
          return unless uri == TEXT_URI
          case local_name
          when "p"
            @in_p = true
          end
        end

        def end_element(uri, local_name, qname)
          @in_p = false

          return unless uri == TEXT_URI
          case local_name
          when "p"
            @output << "\n"
          end
        end

        def characters(text)
          add_text(text)
        end

        def cdata(content)
          add_text(content)
        end

        private
        def add_text(text)
          return unless @in_p
          @output << CGI.unescapeHTML(text)
        end
      end
    end
  end
end
