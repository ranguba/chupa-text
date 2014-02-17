# Copyright (C) 2014  Kouhei Sutou <kou@clear-code.com>
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
  # Attributes of data.
  class Attributes < Struct.new(:title,
                                :author,
                                :encoding,
                                :created_time,
                                :modified_time)
    include Enumerable

    def initialize
      super
      @extra_data = {}
    end

    def to_h
      super.merge(@extra_data)
    end

    def inspect
      super.gsub(/>\z/) do
        " @extra_data=#{@extra_data.inspect}>"
      end
    end

    # @yield [name, value] Gives attribute name and value to the block.
    # @yieldparam [Symbol] name The attribute name.
    # @yieldparam [Object] value The attribute value.
    def each(&block)
      if block.nil?
        Enumerator.new(self, :each)
      else
        each_pair(&block)
        @extra_data.each_pair(&block)
      end
    end

    # Gets the value of attribute named `name`.
    #
    # @param [Symbol, String] name The attribute name.
    # @return [Object] The attribute value.
    def [](name)
      name = normalize_name(name)
      if members.include?(name)
        super
      else
        @extra_data[name]
      end
    end

    # Sets `value` as the value of attribute named `name`.
    #
    # @param [Symbol, String] name The attribute name.
    # @param [Object] value The attribute value.
    def []=(name, value)
      name = normalize_name(name)
      if members.include?(name)
        send("#{name}=", value)
      else
        @extra_data[name] = value
      end
    end

    # Sets `encoding` as the `encoding` attribute value.
    #
    # @param [String, Encoding, nil] encoding The encoding.
    def encoding=(encoding)
      super(normalize_encoding(encoding))
    end

    # Sets `time` as the `created_time` attribute value.
    #
    # @param [String, Integer, Time, nil] time The created time.
    #   If `time` is `Integer`, it is used as UNIX time.
    def created_time=(time)
      super(normalize_time(time))
    end

    # Sets `time` as the `modified_time` attribute value.
    #
    # @param [String, Integer, Time, nil] time The modified time.
    #   If `time` is `Integer`, it is used as UNIX time.
    def modified_time=(time)
      super(normalize_time(time))
    end

    private
    def normalize_name(name)
      name.to_sym
    end

    def normalize_encoding(encoding)
      if encoding.is_a?(String)
        encoding = Encoding.find(encoding)
      end
      encoding
    end

    def normalize_time(time)
      case time
      when String
        Time.parse(time)
      when Integer
        Time.at(time).utc
      else
        time
      end
    end
  end
end
