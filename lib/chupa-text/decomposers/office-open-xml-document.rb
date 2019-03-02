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
    class OfficeOpenXMLDocument < OfficeOpenXML
      registry.register("office-open-xml-document", self)

      def initialize(options={})
        super
        @extensions = [
          "docx",
          "docm",
          "dotx",
          "dotm",
        ]
        @mime_types = [
          "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
          "application/vnd.ms-word.document.macroEnabled.12",
          "application/vnd.openxmlformats-officedocument.wordprocessingml.template",
          "application/vnd.ms-word.template.macroEnabled.12",
        ]
        @namespace_uri =
          "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
      end

      private
      def start_decompose(context)
        context[:text] = ""
      end

      def process_entry(entry, context)
        case entry.zip_path
        when "word/document.xml"
          extract_text(entry, context[:text])
        end
      end

      def finish_decompose(context, &block)
        text_data = TextData.new(context[:text], source_data: context[:data])
        context[:attributes].each do |name, value|
          text_data[name] = value
        end
        yield(text_data)
      end

      def log_tag
        "#{super}[document]"
      end
    end
  end
end
