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

require "English"

module ChupaText
  class SizeParser
    class InvalidSizeError < Error
      attr_reader :size
      def initialize(size)
        @size = size
        super("invalid size: <#{@size.inspect}>")
      end
    end

    class << self
      def parse(size)
        new.parse(size)
      end
    end

    def parse(size)
      case size
      when /TB?\z/i
        scale = 1024 ** 4
        number_part = $PREMATCH
      when /GB?\z/i
        scale = 1024 ** 3
        number_part = $PREMATCH
      when /MB?\z/i
        scale = 1024 ** 2
        number_part = $PREMATCH
      when /KB?\z/i
        scale = 1024 ** 1
        number_part = $PREMATCH
      when /B?\z/i
        scale = 1
        number_part = $PREMATCH
      else
        scale = 1
        number_part = size
      end

      begin
        number = Float(number_part)
      rescue ArgumentError
        raise InvalidSizeError.new(size)
      end
      (number * scale).round
    end
  end
end
