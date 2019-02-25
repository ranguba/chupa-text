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

require "cgi/util"
require "rexml/parsers/sax2parser"
require "rexml/sax2listener"

require "archive/zip"

module ChupaText
  module Decomposers
    class OpenDocument < Decomposer
      registry.register("open-document", self)

      EXTENSIONS = [
        "odt",
      ]
      MIME_TYPES = [
        "application/vnd.oasis.opendocument.text",
      ]
      def target?(data)
        EXTENSIONS.include?(data.extension) or
          MIME_TYPES.include?(data.mime_type)
      end

      def target_score(data)
        if target?(data)
          -1
        else
          nil
        end
      end

      def decompose(data)
        context = {
          text: "",
          attributes: {},
        }
        data.open do |input|
          Archive::Zip.open(input) do |zip|
            zip.each do |entry|
              next unless entry.file?
              case entry.zip_path
              when "content.xml"
                listener = TextListener.new(context[:text])
                parse(entry.file_data, listener)
              when "meta.xml"
                listener = AttributesListener.new(context[:attributes])
                parse(entry.file_data, listener)
              end
            end
          end
        end
        text = context[:text]
        text_data = TextData.new(text, source_data: data)
        context[:attributes].each do |name, value|
          text_data[name] = value
        end
        yield(text_data)
      end

      private
      def parse(io, listener)
        source = REXML::Source.new(io.read)
        parser = REXML::Parsers::SAX2Parser.new(source)
        parser.listen(listener)
        parser.parse
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

      class AttributesListener
        include REXML::SAX2Listener

        META_URI = "urn:oasis:names:tc:opendocument:xmlns:meta:1.0"
        DUBLIN_CORE_URI = "http://purl.org/dc/elements/1.1/"

        def initialize(attributes)
          @attributes = attributes
          @name = nil
          @type = nil
        end

        def start_element(uri, local_name, qname, attributes)
          case uri
          when META_URI
            case local_name
            when "creation-date"
              @name = "created_time"
              @type = :w3cdtf
            when "keyword"
              @name = "keywords"
              @type = :array
            when "generator"
              @name = local_name
            end
          when DUBLIN_CORE_URI
            case local_name
            when "date"
              @name = "modified_time"
              @type = :w3cdtf
            when "description", "title", "subject"
              @name = local_name
            end
          end
        end

        def end_element(uri, local_name, qname)
          @name = nil
          @type = nil
        end

        def characters(text)
          set_attribute(text)
        end

        def cdata(content)
          set_attribute(content)
        end

        def set_attribute(value)
          return if @name.nil?

          value = CGI.unescapeHTML(value)
          case @type
          when :w3cdtf
            value = Time.xmlschema(value)
          when :array
            values = @attributes[@name] || []
            values << value
            value = values
          end
          @attributes[@name] = value
        end
      end
    end
  end
end
