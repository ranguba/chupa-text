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

module ChupaText
  class UTF8Converter
    def initialize(string)
      @string = string
    end

    def convert
      encoding = @string.encoding
      case encoding
      when Encoding::UTF_8
        bom_size, bom_encoding = detect_bom
        if bom_size
          return @string.byteslice(bom_size,
                                   @string.bytesize - bom_size)
        else
          return @string
        end
      when Encoding::ASCII_8BIT
        return @string if @string.ascii_only?
      else
        return @string.encode(Encoding::UTF_8,
                              invalid: :replace,
                              undef: :replace,
                              replace: "")
      end

      bom_size, bom_encoding = detect_bom
      if bom_encoding
        string_without_bom = @string.byteslice(bom_size,
                                               @string.bytesize - bom_size)
        return string_without_bom.encode(Encoding::UTF_8,
                                         bom_encoding,
                                         invalid: :replace,
                                         undef: :replace,
                                         replace: "")
      end

      guessed_encoding = guess_encoding
      if guessed_encoding
        @string.encode(Encoding::UTF_8,
                       guessed_encoding,
                       invalid: :replace,
                       undef: :replace,
                       replace: "")
      else
        utf8_body = @string.dup
        utf8_body.force_encoding(Encoding::UTF_8)
        utf8_body.scrub!("")
        utf8_body.gsub!(/\p{Control}+/, "")
        utf8_body
      end
    end

    private
    UTF_8_BOM = "\xef\xbb\xbf".b
    UTF_16BE_BOM = "\xfe\xff".b
    UTF_16LE_BOM = "\xff\xfe".b
    UTF_32BE_BOM = "\x00\x00\xfe\xff".b
    UTF_32LE_BOM = "\xff\xfe\x00\x00".b
    def detect_bom
      case @string.byteslice(0, 4).b
      when UTF_32BE_BOM
        return 4, Encoding::UTF_32BE
      when UTF_32LE_BOM
        return 4, Encoding::UTF_32LE
      end

      case @string.byteslice(0, 3).b
      when UTF_8_BOM
        return 3, Encoding::UTF_8
      end

      case @string.byteslice(0, 2).b
      when UTF_16BE_BOM
        return 2, Encoding::UTF_16BE
      when UTF_16LE_BOM
        return 2, Encoding::UTF_16LE
      end

      nil
    end

    def guess_encoding
      original_encoding = @string.encoding
      begin
        candidates = [
          Encoding::UTF_8,
          Encoding::EUC_JP,
          Encoding::Windows_31J,
        ]
        candidates.each do |candidate|
          @string.force_encoding(candidate)
          return candidate if @string.valid_encoding?
        end
        nil
      ensure
        @string.force_encoding(original_encoding)
      end
    end
  end
end
