# Copyright (C) 2019  Kouhei Sutou <kou@clear-code.com>
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

require "net/http"
require "pp"
require "uri"

module ChupaText
  module Decomposers
    class HTTPServer < Decomposer
      include Loggable

      registry.register("http-server", self)

      @@default_url = nil
      class << self
        def default_url
          @@default_url
        end

        def default_url=(url)
          @@default_url = url
        end
      end

      def initialize(options)
        super
        @url = @options[:url] ||
               self.class.default_url ||
               ENV["CHUPA_TEXT_HTTP_SERVER_URL"]
        @url = URI(@url) if @url
      end

      def target?(data)
        return false unless @url
        return false if data.text_plain?
        true
      end

      def target_score(data)
        if target?(data)
          100
        else
          nil
        end
      end

      def decompose(data)
        http = Net::HTTP.new(@url.host, @url.port)
        http.use_ssl = true if @url.is_a?(URI::HTTPS)
        http.start do
          request = Net::HTTP::Post.new(@url)
          request["transfer-encoding"] = "chunked"
          data.open do |input|
            request.set_form([
                               [
                                 "data",
                                 input,
                                 {
                                   filename: data.path.to_s,
                                   content_type: data.mime_type,
                                 },
                               ],
                             ],
                             "multipart/form-data")
            response = http.request(request)
            unless response.is_a?(Net::HTTPOK)
              error do
                message = "#{log_tag} Failed to process data in server: "
                message << "#{@url}: "
                message << "#{response.code}: #{response.message.strip}\n"
                case response.content_type
                when "application/json"
                  PP.pp(JSON.parse(response.body), message)
                else
                  message << response.body
                end
                message
              end
              break
            end
            extracted = JSON.parse(response.body)
            (extracted["texts"] || []).each do |text|
              text_data = TextData.new(text["body"], source_data: data)
              text.each do |key, value|
                next if key == "body"
                text_data[key] = value
              end
              yield(text_data)
            end
          end
        end
      end

      private
      def log_tag
        "[decomposer][http-server]"
      end
    end
  end
end
