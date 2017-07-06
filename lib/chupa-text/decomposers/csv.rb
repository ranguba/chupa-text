# Copyright (C) 2013-2017  Kouhei Sutou <kou@clear-code.com>
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
require "csv"

module ChupaText
  module Decomposers
    class CSV < Decomposer
      registry.register("csv", self)

      def target?(data)
        return true if data.mime_type == "text/csv"

        if data.text_plain? and
            (data["source-mime-types"] || []).include?("text/csv")
          return false
        end

        data.extension == "csv"
      end

      def decompose(data)
        text = ""
        data.open do |input|
          csv = ::CSV.new(input)
          csv.each do |row|
            text << row.join(" ")
            text << "\n"
          end
        end

        text_data = TextData.new(text, :source_data => data)
        if data.need_screenshot?
          text_data.screenshot = create_screenshot(data, text)
        end

        yield(text_data)
      end

      private
      def create_screenshot(data, text)
        width, height = data.expected_screenshot_size
        max_n_lines = 10
        font_size = height / max_n_lines
        target_text = ""
        text.each_line.with_index do |line, i|
          break if i == max_n_lines
          target_text << line
        end
        mime_type = "image/svg+xml"
        data = <<-SVG
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg
  xmlns="http://www.w3.org/2000/svg"
  width="#{width}"
  height="#{height}"
  viewBox="0 0 #{width} #{height}">
  <text
    x="0"
    y="#{font_size}"
    style="font-size: #{font_size}px; white-space: pre-wrap;"
    xml:space="preserve">#{CGI.escapeHTML(target_text)}</text>
</svg>
        SVG
        Screenshot.new(mime_type, data)
      end
    end
  end
end
