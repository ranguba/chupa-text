# Copyright (C) 2019-2022  Sutou Kouhei <kou@clear-code.com>
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
      def start_decompose(context)
        context[:shared_strings] = []
        context[:sheet_names] = []
        context[:sheets] = []
      end

      def process_entry(entry, context)
        case entry.zip_path
        when "xl/sharedStrings.xml"
          extract_text(entry, context[:shared_strings])
        when "xl/workbook.xml"
          listener = WorkbookListener.new(context[:sheet_names])
          parse(entry.file_data, listener)
        when /\Axl\/worksheets\/sheet(\d+)\.xml\z/
          nth_sheet = Integer($1, 10)
          sheet = []
          listener = SheetListener.new(sheet)
          parse(entry.file_data, listener)
          context[:sheets] << [nth_sheet, sheet]
        end
      end

      def finish_decompose(context, &block)
        metadata = TextData.new("", source_data: context[:data])
        context[:attributes].each do |name, value|
          metadata[name] = value
        end
        yield(metadata)

        shared_strings = context[:shared_strings]
        sheets = context[:sheets].sort_by(&:first).collect(&:last)
        sheet_names = context[:sheet_names]
        sheets.each_with_index do |sheet, i|
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
          text_data = TextData.new(sheet_text, source_data: context[:data])
          text_data["index"] = i
          name = sheet_names[i]
          text_data["name"] = name if name
          yield(text_data)
        end
      end

      def log_tag
        "#{super}[workbook]"
      end

      class WorkbookListener < SAXListener
        URI = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"

        def initialize(sheet_names)
          @sheet_names = sheet_names
        end

        def start_element(uri, local_name, qname, attributes)
          return unless uri == URI
          case local_name
          when "sheet"
            @sheet_names << attributes["name"]
          end
        end
      end

      class SheetListener < SAXListener
        URI = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"

        def initialize(sheet)
          @sheet = sheet
          @cell_type = nil
          @in_is = false # inline string
          @in_v = false # value
        end

        def start_element(uri, local_name, qname, attributes)
          return unless uri == URI
          case local_name
          when "row"
            @sheet << []
          when "c"
            @cell_type = parse_cell_type(attributes["t"])
          when "is"
            @in_is = true
          when "v"
            @in_v = true
          end
        end

        def end_element(uri, local_name, qname)
          return unless uri == URI
          case local_name
          when "c"
            @cell_type = nil
          when "is"
            @in_is = false
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

        def have_text?
          return true if @in_is
          return true if @in_v
          false
        end

        def add_column(text)
          return unless have_text?
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
