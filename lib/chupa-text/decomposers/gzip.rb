# Copyright (C) 2013-2019  Kouhei Sutou <kou@clear-code.com>
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

require "zlib"

module ChupaText
  module Decomposers
    class Gzip < Decomposer
      include Loggable

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
        open_reader(data) do |reader|
          uri = nil
          case data.extension
          when "gz"
          uri = data.uri.to_s.gsub(/\.gz\z/i, "")
          when "tgz"
            uri = data.uri.to_s.gsub(/\.tgz\z/i, ".tar")
          end
          extracted = VirtualFileData.new(uri, reader, :source_data => data)
          yield(extracted)
        end
      end

      private
      def open_reader(data)
        data.open do |input|
          begin
            yield(Zlib::GzipReader.new(input))
          rescue Zlib::Error => zlib_error
            error do
              message = "#{log_tag} Failed to uncompress: "
              message << "#{zlib_error.class}: #{zlib_error.message}\n"
              message << zlib_error.backtrace.join("\n")
              message
            end
          end
        end
      end

      def log_tag
        "[decomposer][gzip]"
      end
    end
  end
end
