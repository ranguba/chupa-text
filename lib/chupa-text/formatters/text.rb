module ChupaText
  module Formatters
    class Text
      def initialize(output)
        @output = output
        @texts = []
      end

      def format_start(data)
      end

      def format_extracted(data)
        @texts << data.body
      end

      def format_finish(data)
        @output << @texts.join("\n\x0c\n")
        @output << "\n"
      end
    end
  end
end
