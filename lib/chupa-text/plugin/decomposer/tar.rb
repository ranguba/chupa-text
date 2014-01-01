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

require "stringio"
require "rubygems/package"

require "chupa-text"

module ChupaText
  class TarDecomposer < Decomposer
    registry.register(self)

    def target?(data)
      data.extension == "tar" or
        data.content_type == "application/x-tar"
    end

    def decompose(data)
      Gem::Package::TarReader.new(StringIO.new(data.body)) do |reader|
        reader.each do |entry|
          next unless entry.file?
          extracted = Data.new
          extracted.path   = entry.full_name
          extracted.body   = entry.read
          extracted.source = data
          yield(extracted)
        end
      end
    end
  end
end
