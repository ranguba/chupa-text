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

require "pathname"
require "stringio"
require "tempfile"

module ChupaText
  class VirtualContent
    KILO_BYTE = 1024
    BUFFER_SIZE = 64 * KILO_BYTE

    attr_reader :size
    def initialize(input, original_path=nil)
      @file = nil
      if original_path.is_a?(String)
        if original_path.empty?
          original_path = nil
        else
          original_path = Pathname.new(original_path)
        end
      end
      @base_name = compute_base_name(original_path)
      @body = nil
      setup_file do |file|
        @size = IO.copy_stream(input, file)
      end
    end

    def open(&block)
      File.open(path, "rb", &block)
    end

    def body
      @body ||= open {|file| file.read}
    end

    def path
      @path
    end

    private
    def compute_base_name(original_path)
      if original_path
        prefix, suffix = original_path.basename.to_s.split(/(\.[^.]+\z)/)
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
      @file = Tempfile.new(@base_name)
      @path = @file.path
      yield(@file)
      @file.close
    end
  end
end
