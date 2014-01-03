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
require "zlib"

require "chupa-text"

module ChupaText
  module Decomposers
    class Gzip < Decomposer
      registry.register("gzip", self)

      TARGET_EXTENSIONS = ["gz", "tgz"]
      TARGET_MIME_TYPES = [
        "application/gzip",
        "application/x-gzip",
        "application/x-gtar-compressed",
      ]
      def target?(data)
        TARGET_EXTENSIONS.include?(data.extension) or
          TARGET_MIME_TYPES.include?(data.mime_type)
      end

      def decompose(data)
        reader = Zlib::GzipReader.new(StringIO.new(data.body))
        extracted = Data.new
        extracted.body   = reader.read
        case data.extension
        when "gz"
          extracted.uri  = data.uri.to_s.gsub(/\.gz\z/i, "")
        when "tgz"
          extracted.uri  = data.uri.to_s.gsub(/\.tgz\z/i, ".tar")
        end
        extracted.source = data
        yield(extracted)
      end
    end
  end
end
