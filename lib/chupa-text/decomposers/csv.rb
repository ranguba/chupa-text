# Copyright (C) 2013  Kouhei Sutou <kou@clear-code.com>
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

require "csv"

module ChupaText
  module Decomposers
    class CSV < Decomposer
      registry.register("csv", self)

      def target?(data)
        data.extension == "csv" or
          data.mime_type == "text/csv"
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
        text_data = TextData.new(text)
        text_data.uri = data.uri
        yield(text_data)
      end
    end
  end
end
