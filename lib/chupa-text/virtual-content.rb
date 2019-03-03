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

require "pathname"
require "stringio"
require "tempfile"

module ChupaText
  class VirtualContent
    INLINE_MAX_SIZE = 64 * 1024

    attr_reader :size
    def initialize(input, original_path=nil)
      if original_path.is_a?(String)
        if original_path.empty?
          original_path = nil
        else
          original_path = Pathname.new(original_path)
        end
      end
      @original_path = original_path
      body = input.read(INLINE_MAX_SIZE) || ""
      if body.bytesize < INLINE_MAX_SIZE
        @body = body
        @size = @body.bytesize
        @file = nil
        @path = nil
      else
        @body = nil
        setup_file do |file|
          file.write(body)
          @size = body.bytesize
          @size += IO.copy_stream(input, file)
        end
      end
    end

    def open(&block)
      if @body
        super
      else
        File.open(path, "rb", &block)
      end
    end

    def body
      if @body
        @body
      else
        open do |file|
          file.read
        end
      end
    end

    def peek_body(size)
      if @body
        super
      else
        open do |file|
          file.read(size)
        end
      end
    end

    def path
      if @path.nil?
        setup_file do |file|
          file.write(@body)
        end
      end
      @path
    end

    private
    def compute_tempfile_basename
      if @original_path
        prefix, suffix = @original_path.basename.to_s.split(/(\.[^.]+\z)/)
        prefix = prefix[0, 20]
        if suffix
          [prefix, suffix]
        else
          prefix
        end
      else
        "chupa-text-virtual-content"
      end
    end

    def setup_file
      basename = compute_tempfile_basename
      @file = Tempfile.new(basename)
      @file.binmode
      @path = @file.path
      yield(@file)
      @file.close
    end
  end
end
