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

require "chupa-text/mime-type"

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
      @mime_type = nil
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
      File.extname(@uri.path).downcase.gsub(/\A\./, "")
    end

    # @return [Bool] true if MIME type is "text/XXX", false
    #   otherwise.
    def text?
      (mime_type || "").start_with?("text/")
    end

    private
    def retrieve_info(uri)
      if uri.respond_to?(:open)
        uri.open("rb") do |input|
          @body = input.read
          if input.respond_to?(:content_type)
            self.mime_type = input.content_type.split(/;/).first
          end
        end
      else
        File.open(uri.path, "rb") do |file|
          @body = file.read
        end
      end
    end

    def guess_mime_type
      guess_mime_type_from_uri or
        guess_mime_type_from_body
    end

    def guess_mime_type_from_uri
      MIMEType.registry.find(extension)
    end

    def guess_mime_type_from_body
      mime_type = nil
      change_encoding(body, "UTF-8") do |_body|
        mime_type = "text/plain" if _body.valid_encoding?
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
