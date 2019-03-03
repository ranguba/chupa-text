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

require "rubygems/package"

require "chupa-text/path-converter"

module ChupaText
  module Decomposers
    class Tar < Decomposer
      registry.register("tar", self)

      def target?(data)
        data.extension == "tar" or
          data.mime_type == "application/x-tar"
      end

      def decompose(data)
        data.open do |input|
          Gem::Package::TarReader.new(input) do |reader|
            reader.each do |entry|
              next unless entry.file?

              entry.extend(CopyStreamable)
              entry_uri = data.uri.dup
              base_path = entry_uri.path.gsub(/\.tar\z/i, "")
              path_converter = PathConverter.new(entry.full_name,
                                                 uri_escape: true)
              entry_uri.path = "#{base_path}/#{path_converter.convert}"
              entry_data = VirtualFileData.new(entry_uri,
                                               entry,
                                               :source_data => data)
              yield(entry_data)
            end
          end
        end
      end

      # TODO: Supporting output buffer in #read and #readpartial
      # should be done in RubyGems' tar implementation.
      module CopyStreamable
        def readpartial(max_length, buffer=nil)
          data = super(max_length)
          if data.nil?
            if max_length.zero?
              return ""
            else
              raise EOFError
            end
          end

          if buffer.nil?
            data
          else
            buffer.replace(data)
            buffer
          end
        end
      end
    end
  end
end
