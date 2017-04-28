module ChupaText
  module Formatters
    class MIME
      def initialize(output)
        @output = output
        @texts = []
      end

      def format_start(data)
      end

      def format_extracted(data)
        text = format_headers(data)
        text << "\n\n"
        text << data.body
        @texts << text
      end

      def format_finish(data)
        @output << @texts.join("\n\x0c\n")
        @output << "\n"
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
