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
    class OpenDocumentSpreadsheet < OpenDocument
      registry.register("open-document-spreadsheet", self)

      def initialize(options={})
        super
        @extension = "ods"
        @mime_type = "application/vnd.oasis.opendocument.spreadsheet"
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
        sheets = []
        data.open do |input|
          Archive::Zip.open(input) do |zip|
            zip.each do |entry|
              next unless entry.file?
              case entry.zip_path
              when "content.xml"
                listener = SheetsListener.new(sheets)
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
        sheets.each_with_index do |sheet, i|
          text = sheet[:text]
          text_data = TextData.new(text, source_data: data)
          text_data["index"] = i
          name = sheet[:name]
          text_data["name"] = name if name
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

      class SheetsListener
        include REXML::SAX2Listener

        TEXT_URI = "urn:oasis:names:tc:opendocument:xmlns:text:1.0"
        TABLE_URI = "urn:oasis:names:tc:opendocument:xmlns:table:1.0"

        def initialize(sheets)
          @sheets = sheets
          @prefix_to_uri = {}
          @uri_to_prefix = {}
          @in_p = false
        end

        def start_prefix_mapping(prefix, uri)
          @prefix_to_uri[prefix] = uri
          @uri_to_prefix[uri] = prefix
        end

        def end_prefix_mapping(prefix)
          uri = @prefix_to_uri.delete(prefix)
          @uri_to_prefix.delete(uri)
        end

        def start_element(uri, local_name, qname, attributes)
          case uri
          when TEXT_URI
            case local_name
            when "p"
              @in_p = true
            end
          when TABLE_URI
            table_prefix = @uri_to_prefix[TABLE_URI]
            case local_name
            when "table"
              @sheets << {
                name: attributes["#{table_prefix}:name"],
                rows: [],
              }
            when "table-row"
              @sheets.last[:rows] << []
            when "table-cell"
              @sheets.last[:rows].last << {text: ""}
            end
          end
        end

        def end_element(uri, local_name, qname)
          @in_p = false
          case uri
          when TABLE_URI
            case local_name
            when "table"
              sheet = @sheets.last
              text = ""
              sheet[:rows].each do |row|
                cell_texts = row.collect {|cell| cell[:text]}
                next if cell_texts.all?(&:empty?)
                text << cell_texts.join("\t") << "\n"
              end
              sheet[:text] = text
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
          @sheets.last[:rows].last.last[:text] << CGI.unescapeHTML(text)
        end
      end
    end
  end
end
