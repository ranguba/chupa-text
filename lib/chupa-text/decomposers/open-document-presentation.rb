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

require "chupa-text/decomposers/open-document"

module ChupaText
  module Decomposers
    class OpenDocumentPresentation < OpenDocument
      registry.register("open-document-presentation", self)

      def initialize(options={})
        super
        @extension = "odp"
        @mime_type = "application/vnd.oasis.opendocument.presentation"
      end

      def target?(data)
        data.extension == @extension or
          data.mime_type == @mime_type
      end

      def target_score(data)
        if target?(data)
          -1
        else
          nil
        end
      end

      def decompose(data)
        slides = []
        data.open do |input|
          Archive::Zip.open(input) do |zip|
            zip.each do |entry|
              next unless entry.file?
              case entry.zip_path
              when "content.xml"
                listener = SlidesListener.new(slides)
                parse(entry.file_data, listener)
              when "meta.xml"
                attributes = {}
                listener = AttributesListener.new(attributes)
                parse(entry.file_data, listener)
                metadata = TextData.new("", source_data: data)
                attributes.each do |name, value|
                  metadata[name] = value
                end
                yield(metadata)
              end
            end
          end
        end
        slides.each_with_index do |slide, i|
          text = slide[:text]
          text_data = TextData.new(text, source_data: data)
          text_data["index"] = i
          yield(text_data)
        end
      end

      private
      def parse(io, listener)
        source = REXML::Source.new(io.read)
        parser = REXML::Parsers::SAX2Parser.new(source)
        parser.listen(listener)
        parser.parse
      end

      class SlidesListener
        include REXML::SAX2Listener

        TEXT_URI = "urn:oasis:names:tc:opendocument:xmlns:text:1.0"
        DRAW_URI = "urn:oasis:names:tc:opendocument:xmlns:drawing:1.0"

        def initialize(slides)
          @slides = slides
          @in_p = false
        end

        def start_element(uri, local_name, qname, attributes)
          case uri
          when TEXT_URI
            case local_name
            when "p"
              @in_p = true
            end
          when DRAW_URI
            case local_name
            when "page"
              @slides << {text: ""}
            end
          end
        end

        def end_element(uri, local_name, qname)
          @in_p = false
          case uri
          when TEXT_URI
            case local_name
            when "p"
              @slides.last[:text] << "\n"
            end
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
          @slides.last[:text] << CGI.unescapeHTML(text)
        end
      end
    end
  end
end
