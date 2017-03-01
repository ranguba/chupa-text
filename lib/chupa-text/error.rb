# Copyright (C) 2013-2014  Kouhei Sutou <kou@clear-code.com>
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

module ChupaText
  class Error < StandardError
  end

  class EncryptedError < Error
    attr_reader :data
    def initialize(data)
      @data = data
      super("Encrypted data: <#{data.uri}>(#{data.mime_type})")
    end
  end

  class InvalidDataError < Error
    attr_reader :data, :detail
    def initialize(data, detail)
      @data = data
      @detail = detail
      super("Invalid data: <#{data.uri}>(#{data.mime_type}): <#{detail}>")
    end
  end

  class UnknownEncodingError < Error
    attr_reader :data, :encoding
    def initialize(data, encoding)
      @data = data
      @encoding = encoding
      super("Unknown encoding data: <#{data.uri}>(#{data.mime_type}): <#{encoding}>")
    end
  end
end
