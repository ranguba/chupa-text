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

require "stringio"
require "tmpdir"

require "archive/zip"

module ChupaText
  module Decomposers
    class Zip < Decomposer
      registry.register("zip", self)

      def target?(data)
        return true if data.extension == "zip"
        return true if data.mime_type == "application/zip"

        false
      end

      def decompose(data)
        Archive::Zip.open(StringIO.new(data.body)) do |zip|
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
            path = convert_path_encoding(entry.zip_path, base_path.encoding)
            entry_uri.path = "#{base_path}/#{convert_to_uri_path(path)}"
            entry_data = VirtualFileData.new(entry_uri,
                                             entry.file_data,
                                             source_data: data)
            yield(entry_data)
          end
        end
      end

      private
      def convert_path_encoding(path, encoding)
        return path if path.ascii_only?

        candidates = [
          Encoding::UTF_8,
          Encoding::Windows_31J,
        ]
        candidates.each do |candidate|
          path.force_encoding(candidate)
          return path.encode(encoding) if path.valid_encoding?
        end
        path.encode(encoding,
                    Encoding::UTF_8,
                    invalid: :replace,
                    undef: :replace)
      end

      def convert_to_uri_path(path)
        converted_components = path.split("/").collect do |component|
          CGI.escape(component)
        end
        converted_components.join("/")
      end
    end
  end
end
