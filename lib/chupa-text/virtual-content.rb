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
require "tempfile"

module ChupaText
  class VirtualContent
    KILO_BYTE = 1024
    BUFFER_SIZE = 64 * KILO_BYTE

    attr_reader :size
    def initialize(input, original_path=nil)
      @file = nil
      @base_name = compute_base_name(original_path)
      chunk = input.read(BUFFER_SIZE) || ""
      if chunk.bytesize != BUFFER_SIZE
        @path = nil
        @body = chunk
        @size = @body.bytesize
      else
        @body = nil
        @size = chunk.bytesize
        setup_file do |file|
          file.write(chunk)
          while (chunk = input.read(BUFFER_SIZE))
            @size += chunk.bytesize
            file.write(chunk)
          end
        end
      end
    end

    def open(&block)
      if @body
        yield(StringIO.new(@body))
      else
        File.open(path, "rb", &block)
      end
    end

    def body
      @body ||= open {|file| file.read}
    end

    def path
      ensure_setup_file do |file|
        file.write(@body)
      end
      @path
    end

    private
    def compute_base_name(original_path)
      if original_path
        prefix, suffix = File.basename(original_path).split(/(\.[^.]+\z)/)
        if suffix
          [prefix, suffix]
        else
          prefix
        end
      else
        "chupa-text-virtual-content"
      end
    end

    def ensure_setup_file(&block)
      setup_file(&block) unless @file
    end

    def setup_file
      @file = Tempfile.new(@base_name)
      @path = @file.path
      yield(@file)
      @file.close
    end
  end
end
