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

require "uri"
require "open-uri"

require "chupa-text/content-type"

module ChupaText
  class Data
    attr_accessor :body
    attr_accessor :attributes

    # @return [URI, nil] The URI of the data if the data is for remote
    #   or local file, `nil` if the data isn't associated with any
    #   URIs.
    attr_reader :uri

    # @return [Data, nil] The source of the data. For example, text
    #   data (`hello.txt`) in archive data (`hello.tar`) have the
    #   archive data in {#source}.
    attr_accessor :source

    def initialize
      @body = nil
      @attributes = {}
      @uri = nil
      @source = nil
    end

    def initialize_copy(object)
      super
      @attributes = @attributes.dup
      self
    end

    # @param [String, URI, nil] uri The URI for the data. If `uri` is
    #   `nil`, it means that the data isn't associated with any URIs.
    def uri=(uri)
      case uri
      when String, Pathname
        uri = URI.parse(uri.to_s)
      end
      @uri = uri
      if @uri and @body.nil?
        retrieve_info(@uri)
      end
    end

    def size
      _body = body
      return 0 if _body.nil?
      _body.bytesize
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

    # @return [String, nil] Normalized extension as String if {#uri}
    #   is not `nil`, `nil` otherwise. The normalized extension uses
    #   lower case like `pdf` not `PDF`.
    def extension
      return nil if @uri.nil?
      File.extname(@uri.path).downcase.gsub(/\A\./, "")
    end

    # @return [Bool] true if content-type is "text/plain", false
    #   otherwise.
    def text?
      (content_type || "").start_with?("text/")
    end

    private
    def retrieve_info(uri)
      if uri.respond_to?(:open)
        uri.open("rb") do |input|
          @body = input.read
          if input.respond_to?(:content_type)
            self.content_type = input.content_type
          end
        end
      else
        File.open(uri.path, "rb") do |file|
          @body = file.read
        end
      end
    end

    def guess_content_type
      guess_content_type_from_uri or
        guess_content_type_from_body
    end

    def guess_content_type_from_uri
      ContentType.registry.find(extension)
    end

    def guess_content_type_from_body
      content_type = nil
      change_encoding(body, "UTF-8") do |_body|
        content_type = "text/plain" if _body.valid_encoding?
      end
      content_type
    end

    def change_encoding(string, encoding)
      return if string.nil?
      begin
        original_encoding = string.encoding
        string.force_encoding(encoding)
        yield(string)
      ensure
        string.force_encoding(original_encoding)
      end
    end
  end
end
