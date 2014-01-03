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

module ChupaText
  class MIMETypeRegistry
    def initialize
      @from_extension_map = {}
    end

    def register(extension, mime_type)
      @from_extension_map[normalize_extension(extension)] = mime_type
    end

    def find(extension)
      @from_extension_map[normalize_extension(extension)]
    end

    def clear
      @from_extension_map.clear
    end

    private
    def normalize_extension(extension)
      return nil if extension.nil?
      extension.to_s.downcase.gsub(/\A\./, "")
    end
  end
end
