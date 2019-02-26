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

      def decompose(data, &block)
        context = {
          data: data,
          attributes: {},
        }
        data.open do |input|
          Archive::Zip.open(input) do |zip|
            zip.each do |entry|
              next unless entry.file?
              case entry.zip_path
              when "content.xml"
                process_content(entry, context, &block)
              when "meta.xml"
                process_meta(entry, context, &block)
              end
            end
          end
        end
        finish_decompose(context, &block)
      end

      private
      def parse(io, listener)
        source = REXML::Source.new(io.read)
        parser = REXML::Parsers::SAX2Parser.new(source)
        parser.listen(listener)
        parser.parse
      end

      def process_meta(entry, context, &block)
        listener = AttributesListener.new(context[:attributes])
        parse(entry.file_data, listener)
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
