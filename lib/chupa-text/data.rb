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

module ChupaText
  class Data
    class << self
      def open(path)
        data = new
        data.path = path
        if block_given?
          yield(data)
        else
          data
        end
      end
    end

    attr_writer :body
    attr_accessor :attributes
    attr_reader :path

    def initialize
      @body = nil
      @attributes = {}
      @path = nil
    end

    def body
      @body ||= read_body
    end

    def path=(path)
      path = Pathname(path) if path.is_a?(String)
      @path = path
    end

    def [](name)
      @attributes[name]
    end

    def []=(name, value)
      @attributes[name] = value
    end

    def content_type
      self["content-type"]
    end

    def content_type=(type)
      self["content-type"] = type
    end

    private
    def read_body
      return nil if @path.nil?
      @path.open("rb") do |file|
        file.read
      end
    end
  end
end
