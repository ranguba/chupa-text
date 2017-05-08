require "digest/sha1"

module ChupaText
  module Formatters
    class MIME
      def initialize(output)
        @output = output
        @texts = []
      end

      def format_start(data)
        @output << "Original-URI: #{data.uri}\n"
        @output << "Content-Size: #{data.size}\n"
      end

      def format_extracted(data)
        text = format_headers(data)
        text << "\n\n"
        text << data.body
        @texts << text
      end

      def format_finish(data)
        if @texts.size > 1
          boundary = Digest::SHA1.hexdigest(data.uri.to_s)
          @output << "Content-Type: multipart/mixed; boundary=#{boundary}\n\n"
          @output << "--#{boundary}\n"
          @output << @texts.join("\n\n--#{boundary}\n")
          @output << "\n--#{boundary}--\n"
        else
          @output << @texts.first
          @output << "\n"
        end
      end

      private
      def format_headers(data)
        headers = {}
        headers["mime-type"] = data.mime_type
        headers["uri"] =  data.uri
        headers["size"] = data.size
        data.attributes.each do |name, value|
          headers[name] = value
        end
        headers.map do |name, value|
          "#{name}: #{value}"
        end.join("\n")
      end
    end
  end
end
