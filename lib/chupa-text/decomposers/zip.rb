# Copyright (C) 2017-2019  Kouhei Sutou <kou@clear-code.com>
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

require "chupa-text/path-converter"

module ChupaText
  module Decomposers
    class Zip < Decomposer
      include Loggable
      include Unzippable

      registry.register("zip", self)

      def target?(data)
        return true if data.extension == "zip"
        return true if data.mime_type == "application/zip"

        false
      end

      def decompose(data)
        unzip(data) do |zip|
          zip.each do |entry|
            next unless entry.file?

            case entry.encryption_codec
            when Archive::Zip::Codec::NullEncryption
            else
              # TODO
              # entry.password = ...
              raise EncryptedError.new(data)
            end
            entry_uri = data.uri.dup
            base_path = entry_uri.path.gsub(/\.zip\z/i, "")
            path_converter = PathConverter.new(entry.zip_path,
                                               encoding: base_path.encoding,
                                               uri_escape: true)
            entry_uri.path = "#{base_path}/#{path_converter.convert}"
            size = entry.raw_data.window_size
            entry_data = VirtualFileData.new(entry_uri,
                                             entry.file_data,
                                             source_data: data)
            yield(entry_data)
          end
        end
      end

      private
      def log_tag
        "[decomposer][zip]"
      end
    end
  end
end
