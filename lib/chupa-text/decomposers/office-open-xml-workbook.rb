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

require "chupa-text/decomposers/office-open-xml"

module ChupaText
  module Decomposers
    class OfficeOpenXMLWorkbook < OfficeOpenXML
      registry.register("office-open-xml-workbook", self)

      def initialize(options={})
        super
        @extensions = [
          "xlsx",
          "xlsm",
          "xltx",
          "xltm",
        ]
        @mime_types = [
          "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
          "application/vnd.ms-excel.sheet.macroEnabled.12",
          "application/vnd.openxmlformats-officedocument.spreadsheetml.template",
          "application/vnd.ms-excel.template.macroEnabled.12",
        ]
        @namespace_uri =
          "http://schemas.openxmlformats.org/spreadsheetml/2006/main"
      end

      private
      def process_entry(entry, context)
        case entry.zip_path
        when "xl/sharedStrings.xml"
          context[:shared_strings] = []
          extract_text(entry, context[:shared_strings])
        when /\Axl\/worksheets\/sheet(\d+)\.xml\z/
          nth_sheet = Integer($1, 10)
          sheet = []
          listener = SheetListener.new(sheet)
          parse(entry.file_data, listener)
          context[:sheets] ||= []
          context[:sheets] << [nth_sheet, sheet]
        end
      end

      def accumulate_text(context)
        shared_strings = context[:shared_strings]
        sheets = context[:sheets].sort_by(&:first).collect(&:last)
        sheet_texts = sheets.collect do |sheet|
          sheet_text = ""
          sheet.each do |row|
            row_texts = row.collect do |cell|
              case cell
              when Integer
                shared_strings[cell]
              else
                cell
              end
            end
            sheet_text << row_texts.join("\t") << "\n"
          end
          sheet_text
        end
        sheet_texts.join("\n")
      end

      class SheetListener < SAXListener
        URI = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"

        def initialize(sheet)
          @sheet = sheet
          @cell_type = nil
          @in_v = false
        end

        def start_element(uri, local_name, qname, attributes)
          return unless uri == URI
          case local_name
          when "row"
            @sheet << []
          when "c"
            @cell_type = parse_cell_type(attributes["t"])
          # when "is" # TODO
          when "v"
            @in_v = true
          end
        end

        def end_element(uri, local_name, qname)
          return unless uri == URI
          case local_name
          when "c"
            @cell_type = nil
          when "v"
            @in_v = false
          end
        end

        def characters(text)
          add_column(text)
        end

        def cdata(content)
          add_column(content)
        end

        private
        # https://c-rex.net/projects/samples/ooxml/e1/Part4/OOXML_P4_DOCX_ST_CellType_topic_ID0E6NEFB.html
        def parse_cell_type(type)
          case type
          when "b"
            :boolean
          when "e"
            :error
          when "inlineStr"
            :inline_string
          when "n"
            :number
          when "s"
            :shared_string
          when "str"
            :string
          else
            nil
          end
        end

        def add_column(text)
          return unless @in_v
          case @cell_type
          when :shared_string
            @sheet.last << Integer(text, 10)
          else
            @sheet.last << text
          end
        end
      end
    end
  end
end
