# Copyright (C) 2019  Sutou Kouhei <kou@clear-code.com>
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
  class TimeoutValue
    include Comparable
    include Loggable

    attr_reader :raw
    def initialize(tag, value)
      value = parse(value) if value.is_a?(String)
      @raw = value
    end

    def to_s
      return "" if @raw.nil?

      if @raw < 1
        "%.2fms" % (@raw * 1000.0)
      elsif @raw < 60
        "%.2fs" % @raw
      elsif @raw < (60 * 60)
        "%.2fm" % (@raw / 60.0)
      else
        "%.2fh" % (@raw / 60.0 / 60.0)
      end
    end

    private
    def parse(value)
      case value
      when nil
        nil
      when Numeric
        value
      else
        return nil if value.empty?
        scale = 1
        case value
        when /h\z/i
          scale = 60 * 60
          number = $PREMATCH
        when /m\z/i
          scale = 60
          number = $PREMATCH
        when /s\z/i
          number = $PREMATCH
        else
          number = value
        end
        begin
          number = Float(number)
        rescue ArgumentError
          log_invalid_value(@tag, value, "time")
          return nil
        end
        (number * scale).to_f
      end
    end
  end
end
