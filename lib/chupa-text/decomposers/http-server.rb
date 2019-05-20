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
        @url = @options[:url]
        @url = URI(@url) if @url
      end

      def target?(data)
        return false if data.text_plain?
        @url or default_url
      end

      def target_score(data)
        if target?(data)
          -100
        else
          nil
        end
      end

      def decompose(data, &block)
        url = @url || default_url
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true if url.is_a?(URI::HTTPS)
        if data.timeout.is_a?(Numeric)
          http.open_timeout = data.timeout * 1.5
          http.read_timeout = data.timeout * 1.5
          if http.respond_to?(:write_timeout=)
            http.write_timeout = data.timeout * 1.5
          end
        end
        begin
          http.start do
            process_request(url, http, data, &block)
          end
        rescue SystemCallError => error
          error do
            message = "#{log_tag}[connection] "
            message << "Failed to process data in server: "
            message << "#{url}: "
            message << "#{error.class}: #{error.message}\n"
            message << error.backtrace.join("\n")
            message
          end
        rescue Net::ReadTimeout => error
          error do
            message = "#{log_tag}[timeout] "
            message << "Failed to process data in server: "
            message << "#{url}: "
            message << "#{error.class}: #{error.message}\n"
            message << error.backtrace.join("\n")
            message
          end
        end
      end

      private
      def default_url
        url = self.class.default_url || ENV["CHUPA_TEXT_HTTP_SERVER_URL"]
        return nil if url.nil?
        URI(url)
      end

      def process_request(url, http, data)
        request = Net::HTTP::Post.new(url)
        request["transfer-encoding"] = "chunked"
        data.open do |input|
          request.set_form(build_parameters(data, input),
                           "multipart/form-data")
          response = http.request(request)
          case response
          when Net::HTTPOK
            extracted = JSON.parse(response.body)
            (extracted["texts"] || []).each do |text|
              text_data = TextData.new(text["body"], source_data: data)
              text.each do |key, value|
                next if key == "body"
                text_data[key] = value
              end
              yield(text_data)
            end
          else
            error do
              message = "#{log_tag} Failed to process data in server: "
              message << "#{url}: "
              message << "#{response.code}: #{response.message.strip}\n"
              case response.content_type
              when "application/json"
                PP.pp(JSON.parse(response.body), message)
              else
                message << response.body
              end
              message
            end
          end
        end
      end

      def build_parameters(data, input)
        parameters = []
        [
          ["timeout",
           data.timeout || ChupaText::ExternalCommand.default_timeout],
          ["limit_cpu",
           data.limit_cpu || ChupaText::ExternalCommand.default_limit_cpu],
          ["limit_as",
           data.limit_as || ChupaText::ExternalCommand.default_limit_as],
          ["max_body_size", data.max_body_size],
        ].each do |key, value|
          next if value.nil?
          parameters << [key, StringIO.new(value.to_s)]
        end
        parameters << [
          "data",
          input,
          {
            filename: data.path.to_s,
            content_type: data.mime_type,
          },
        ]
        parameters
      end

      def log_tag
        "[decomposer][http-server]"
      end
    end
  end
end
