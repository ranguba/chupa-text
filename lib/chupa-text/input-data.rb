# Copyright (C) 2013-2017  Kouhei Sutou <kou@clear-code.com>
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

require "cgi/util"
require "uri"
require "open-uri"

module ChupaText
  class InputData < Data
    def initialize(uri, options={})
      super(options)
      self.uri = uri
      if @uri.class == URI::Generic
        @content = FileContent.new(path)
      else
        @content = download
        self.path = @content.path
      end
    end

    def body
      @content.body
    end

    def size
      @content.size
    end

    def open(&block)
      @content.open(&block)
    end

    private
    def download
      path = @uri.path
      path += "index.html" if path.end_with?("/")
      @uri.open("rb") do |input|
        self.mime_type = input.content_type.split(/;/).first
        VirtualContent.new(input, path)
      end
    end
  end
end
