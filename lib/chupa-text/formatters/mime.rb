# Copyright (C) 2017  Kenji Okimoto <okimoto@clear-code.com>
# Copyright (C) 2017  Kouhei Sutou <kou@clear-code.com>
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

require "digest/sha1"

require "chupa-text/formatters/hash"

module ChupaText
  module Formatters
    class MIME < Hash
      def initialize(output, options={})
        super()
        @output = output
        @boundary = options[:boundary]
      end

      def format_finish(data)
        formatted = super

        @output << "MIME-Version: 1.0\r\n"
        format_hash(formatted, ["texts"])
        texts = formatted["texts"]
        boundary = @boundary || Digest::SHA1.hexdigest(data.uri.to_s)
        @output << "Content-Type: multipart/mixed; boundary=#{boundary}\r\n"
        texts.each do |text|
          @output << "\r\n--#{boundary}\r\n"
          format_text(text)
        end
        @output << "\r\n--#{boundary}--\r\n"
      end

      private
      def format_hash(hash, ignore_keys)
        hash.each do |key, value|
          next if ignore_keys.include?(key)
          @output << "#{key}: #{value}\r\n"
        end
      end

      def format_text(hash)
        format_hash(hash, ["body"])
        body = hash["body"]
        if body
          @output << "\r\n"
          @output << body
        end
      end
    end
  end
end
