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

require "cgi/util"
require "uri"
require "open-uri"

require "chupa-text/utf8-converter"

module ChupaText
  class Data
    # @return [URI, nil] The URI of the data if the data is for remote
    #   or local file, `nil` if the data isn't associated with any
    #   URIs.
    attr_reader :uri

    # @return [String, nil] The content of the data, `nil` if the data
    #   doesn't have any content.
    attr_accessor :body

    # @return [Integer, nil] The byte size of the data, `nil` if the data
    #   doesn't have any content.
    attr_accessor :size

    # @return [String, nil] The path associated with the content of
    #   the data, `nil` if the data doesn't associated with any file.
    #
    #   The path may not be related with the original content. For
    #   example, `"/tmp/XXX.txt"` may be returned for the data of
    #   `"http://example.com/XXX.txt"`.
    #
    #   This value is useful to use an external command to extract
    #   text and meta-data.
    attr_accessor :path

    # @return [Attributes] The attributes of the data.
    attr_reader :attributes

    # @return [Data, nil] The source of the data. For example, text
    #   data (`hello.txt`) in archive data (`hello.tar`) have the
    #   archive data in {#source}.
    attr_accessor :source

    # @return [Screenshot, nil] The screenshot of the data. For example,
    #   the first page image for PDF file.text.
    attr_accessor :screenshot

    # @param [Bool] value `true` when screenshot is needed.
    # @return [Bool] the specified value
    attr_writer :need_screenshot

    # @return [Array<Integer, Integer>] the expected screenshot size.
    attr_accessor :expected_screenshot_size

    def initialize(options={})
      @uri = nil
      @body = nil
      @size = nil
      @path = nil
      @mime_type = nil
      @attributes = Attributes.new
      @source = nil
      @screenshot = nil
      @need_screenshot = true
      @expected_screenshot_size = [200, 200]
      @options = options || {}
      source_data = @options[:source_data]
      if source_data
        merge!(source_data)
        @source = source_data
      end
    end

    def initialize_copy(object)
      super
      @attributes = @attributes.dup
      self
    end

    # Merges metadata from data.
    #
    # @param [Data] data The data to be merged.
    #
    # @return [void]
    def merge!(data)
      self.uri = data.uri
      self.path = data.path
      data.attributes.each do |name, value|
        self[name] = value
      end
      if data.mime_type
        self["source-mime-types"] ||= []
        self["source-mime-types"].unshift(data.mime_type)
      end
      self.need_screenshot = data.need_screenshot?
      self.expected_screenshot_size = data.expected_screenshot_size
    end

    # @param [String, URI, nil] uri The URI for the data. If `uri` is
    #   `nil`, it means that the data isn't associated with any URIs.
    def uri=(uri)
      case uri
      when Pathname
        file_uri = ""
        target = uri.expand_path
        loop do
          target, base = target.split
          file_uri = "/#{CGI.escape(base.to_s)}#{file_uri}"
          break if target.root?
        end
        file_uri = "file://#{file_uri}"
        @uri = URI.parse(file_uri)
        self.path = uri
      when NilClass
        @uri = nil
        self.path = nil
      else
        unless uri.is_a?(URI)
          uri = URI.parse(uri)
        end
        @uri = uri
        self.path = @uri.path
      end
    end

    def open
      yield(StringIO.new(body))
    end

    def peek_body(size)
      _body = body
      return nil if _body.nil?
      _body[0, size]
    end

    def [](name)
      @attributes[name]
    end

    def []=(name, value)
      @attributes[name] = value
    end

    # @return [String] The MIME type of the data. If MIME type
    #   isn't set, guesses MIME type from path and body.
    # @return [nil] If MIME type isn't set and it can't guess MIME type
    #   from path and body.
    def mime_type
      @mime_type || guess_mime_type
    end

    # @param [String, nil] type The MIME type of the data. You can
    #   unset MIME type by `nil`. If you unset MIME type, MIME type
    #   is guessed from path and body of the data.
    def mime_type=(type)
      @mime_type = type
    end

    # @return [String, nil] Normalized extension as String if {#uri}
    #   is not `nil`, `nil` otherwise. The normalized extension uses
    #   lower case like `pdf` not `PDF`.
    def extension
      return nil if @uri.nil?
      if @uri.is_a?(URI::HTTP) and @uri.path.end_with?("/")
        "html"
      else
        File.extname(@uri.path).downcase.gsub(/\A\./, "")
      end
    end

    # @return [Bool] true if MIME type is "text/XXX", false
    #   otherwise.
    def text?
      (mime_type || "").start_with?("text/")
    end

    # @return [Bool] true if MIME type is "text/plain", false
    #   otherwise.
    def text_plain?
      mime_type == "text/plain"
    end

    # @return [Bool] `true` when screenshot is needed if available.
    def need_screenshot?
      @need_screenshot
    end

    def to_utf8_body_data
      b = body
      return self if b.nil?
      converter = UTF8Converter.new(b)
      utf8_body = converter.convert
      if b.equal?(utf8_body)
        self
      else
        TextData.new(utf8_body, source_data: self)
      end
    end

    private
    def guess_mime_type
      guess_mime_type_from_uri or
        guess_mime_type_from_body
    end

    def guess_mime_type_from_uri
      MIMEType.registry.find(extension)
    end

    def guess_mime_type_from_body
      mime_type = nil
      chunk = peek_body(1024)
      change_encoding(chunk, "UTF-8") do |utf8_chunk|
        return nil unless utf8_chunk.valid_encoding?
        n_null_characters = utf8_chunk.count("\u0000")
        return nil if n_null_characters > (utf8_chunk.bytesize * 0.01)
        mime_type = "text/plain"
      end
      mime_type
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
