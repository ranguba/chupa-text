# Copyright (C) 2019-2024  Sutou Kouhei <kou@clear-code.com>
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
    class OpenDocumentPresentation < OpenDocument
      registry.register("opendocument-presentation", self)

      def initialize(options={})
        super
        @extension = "odp"
        @mime_type = "application/vnd.oasis.opendocument.presentation"
      end

      private
      def process_content(entry, context, &block)
        context[:slides] = []
        listener = SlidesListener.new(context[:slides])
        parse(entry.file_data, listener)
      end

      def finish_decompose(context, &block)
        metadata = TextData.new("", source_data: context[:data])
        context[:attributes].each do |name, value|
          metadata[name] = value
        end
        yield(metadata)

        (context[:slides] || []).each_with_index do |slide, i|
          text = slide[:text]
          text_data = TextData.new(text, source_data: context[:data])
          text_data["index"] = i
          yield(text_data)
        end
      end

      def log_tag
        "#{super}[presentation]"
      end

      class SlidesListener < SAXListener
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
              @slides << {text: +""}
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
          @slides.last[:text] << text
        end
      end
    end
  end
end
