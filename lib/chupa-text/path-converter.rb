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

module ChupaText
  class PathConverter
    def initialize(path, options={})
      @path = path
      @options = options
    end

    def convert
      path = @path
      encoding = @options[:encoding]
      path = convert_encoding(path, encoding) if encoding
      path = convert_to_uri_path(path) if @options[:uri_escape]
      path
    end

    private
    def convert_encoding(path, encoding)
      case path.encoding
      when Encoding::ASCII_8BIT
        if path.ascii_only?
          path.force_encoding(Encoding::UTF_8)
        else
          candidates = [
            Encoding::UTF_8,
            Encoding::EUC_JP,
            Encoding::Windows_31J,
          ]
          found = false
          candidates.find do |candidate|
            path.force_encoding(candidate)
            if path.valid_encoding?
              found = true
              break
            end
          end
          path.force_encoding(Encoding::ASCII_8BIT) unless found
        end
      end
      path.encode(encoding,
                  invalid: :replace,
                  undef: :replace,
                  replace: "")
    end

    def convert_to_uri_path(path)
      converted_components = path.split("/").collect do |component|
        CGI.escape(component)
      end
      converted_components.join("/")
    end
  end
end
