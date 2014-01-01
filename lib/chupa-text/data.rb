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
      self["content-type"] || guess_content_type
    end

    def content_type=(type)
      self["content-type"] = type
    end

    # @return [String, nil] Normalized extension as String if {#path}
    #   is not `nil`, `nil` otherwise. The normalized extension uses
    #   lower case like `.pdf` not `.PDF`.
    def extension
      return nil if @path.nil?
      @path.extname.downcase
    end

    # @return [Bool] true if content-type is "text/plain", false
    #   otherwise.
    def text?
      content_type == "text/plain"
    end

    private
    def read_body
      return nil if @path.nil?
      @path.open("rb") do |file|
        file.read
      end
    end

    def guess_content_type
      guess_content_type_from_path or
        guess_content_type_from_body
    end

    EXTENSION_TO_CONTENT_TYPE_MAP = {
      ".txt" => "text/plain",
    }
    def guess_content_type_from_path
      return nil if @path.nil?
      EXTENSION_TO_CONTENT_TYPE_MAP[@path.extname.downcase]
    end

    def guess_content_type_from_body
      nil
    end
  end
end
