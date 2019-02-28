# Copyright (C) 2013-2017  Kouhei Sutou <kou@clear-code.com>
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
require "uri"

module ChupaText
  class Extractor
    include Loggable

    def initialize
      @decomposers = []
    end

    # Sets the extractor up by the configuration. It adds decomposers
    # enabled in the configuration.
    #
    # @param [Configuration] configuration The configuration to be
    #   applied.
    #
    # @return [void]
    def apply_configuration(configuration)
      decomposers = Decomposers.create(Decomposer.registry,
                                       configuration.decomposer)
      decomposers.each do |decomposer|
        add_decomposer(decomposer)
      end
    end

    def add_decomposer(decomposer)
      @decomposers << decomposer
    end

    # Extracts texts from input. Each extracted text is passes to the
    # given block.
    #
    # @param [Data, String] input The input to be extracted texts.
    #   If `input` is `String`, it is treated as the local file path or URI
    #   of input data.
    #
    # @yield [text_data] Gives extracted text data to the block.
    #   The block may be called zero or more times.
    # @yieldparam [Data] text_data The extracted text data.
    #   You can get text data by `text_data.body`.
    #
    # @return [void]
    def extract(input)
      targets = [ensure_data(input)]
      until targets.empty?
        target = targets.shift
        debug do
          "#{log_tag}[extract][target] <#{target.uri}>:<#{target.mime_type}>"
        end
        decomposer = find_decomposer(target)
        if decomposer.nil?
          if target.text_plain?
            debug {"#{log_tag}[extract][text-plain]"}
            yield(ensure_utf8_body_data(target))
            next
          else
            debug {"#{log_tag}[extract][decomposer] not found"}
            if target.text?
              yield(ensure_utf8_body_data(target))
            end
            next
          end
        end
        debug {"#{log_tag}[extract][decomposer] #{decomposer.class}"}
        decomposer.decompose(target) do |decomposed|
          debug do
            "#{log_tag}[extract][decomposed] " +
              "#{decomposer.class}: " +
              "<#{target.uri}>: " +
              "<#{target.mime_type}> -> <#{decomposed.mime_type}>"
          end
          targets.push(decomposed)
        end
      end
    end

    private
    def ensure_data(input)
      if input.is_a?(Data)
        input
      else
        InputData.new(input)
      end
    end

    def ensure_utf8_body_data(data)
      body = data.body
      return dat if body.nil?

      encoding = body.encoding
      case encoding
      when Encoding::UTF_8
        bom_size, bom_encoding = detect_bom(body)
        if bom_size
          body_without_bom = body.byteslice(bom_size,
                                            body.byteslice - bom_size)
          return TextData.new(body_without_bom, source_data: data)
        else
          return data
        end
      when Encoding::ASCII_8BIT
        return data if body.ascii_only?
      else
        utf8_body = body.encode(Encoding::UTF_8,
                                invalid: :replace,
                                undef: :replace,
                                replace: "")
        return TextData.new(utf8_body, source_data: data)
      end

      bom_size, bom_encoding = detect_bom(body)
      if bom_encoding
        body_without_bom = body.byteslice(bom_size, body.bytesize - bom_size)
        utf8_body = body_without_bom.encode(Encoding::UTF_8,
                                            bom_encoding,
                                            invalid: :replace,
                                            undef: :replace,
                                            replace: "")
        return TextData.new(utf8_body, source_data: data)
      end

      candidates = [
        Encoding::UTF_8,
        Encoding::EUC_JP,
        Encoding::Windows_31J,
      ]
      candidates.each do |candidate|
        body.force_encoding(candidate)
        if body.valid_encoding?
          utf8_body = body.encode(Encoding::UTF_8,
                                  invalid: :replace,
                                  undef: :replace,
                                  replace: "")
          return TextData.new(utf8_body, source_data: data)
        end
      end
      body.force_encoding(encoding)
      data
    end

    UTF_8_BOM = "\xef\xbb\xbf".b
    UTF_16BE_BOM = "\xfe\xff".b
    UTF_16LE_BOM = "\xff\xfe".b
    UTF_32BE_BOM = "\x00\x00\xfe\xff".b
    UTF_32LE_BOM = "\xff\xfe\x00\x00".b
    def detect_bom(text)
      case text.byteslice(0, 4).b
      when UTF_32BE_BOM
        return 4, Encoding::UTF_32BE
      when UTF_32LE_BOM
        return 4, Encoding::UTF_32LE
      end

      case text.byteslice(0, 3).b
      when UTF_8_BOM
        return 3, Encoding::UTF_8
      end

      case text.byteslice(0, 2).b
      when UTF_16BE_BOM
        return 2, Encoding::UTF_16BE
      when UTF_16LE_BOM
        return 2, Encoding::UTF_16LE
      end

      nil
    end

    def find_decomposer(data)
      candidates = []
      @decomposers.each do |decomposer|
        score = decomposer.target_score(data)
        next if score.nil?
        candidates << [score, decomposer]
      end
      return nil if candidates.empty?
      candidate = candidates.sort_by {|score, _| score}.first
      candidate[1]
    end

    def log_tag
      "[extractor]"
    end
  end
end
