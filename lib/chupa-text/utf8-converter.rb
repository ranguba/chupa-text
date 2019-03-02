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
    def initialize(string, max_size: nil)
      @string = string
      @max_size = max_size
    end

    def convert
      encoding = @string.encoding
      case encoding
      when Encoding::UTF_8
        bom_size, bom_encoding = detect_bom
        if bom_size
          utf8_string = @string.byteslice(bom_size,
                                          @string.bytesize - bom_size)
        else
          utf8_string = @string
        end
        return truncate(utf8_string)
      when Encoding::ASCII_8BIT
        return truncate(@string) if @string.ascii_only?
      else
        utf8_string = @string.encode(Encoding::UTF_8,
                                     invalid: :replace,
                                     undef: :replace,
                                     replace: "")
        return truncate(utf8_string)
      end

      bom_size, bom_encoding = detect_bom
      if bom_encoding
        string_without_bom = @string.byteslice(bom_size,
                                               @string.bytesize - bom_size)
        utf8_string = string_without_bom.encode(Encoding::UTF_8,
                                                bom_encoding,
                                                invalid: :replace,
                                                undef: :replace,
                                                replace: "")
        return truncate(utf8_string)
      end

      guessed_encoding = guess_encoding
      if guessed_encoding
        truncate(@string.encode(Encoding::UTF_8,
                                guessed_encoding,
                                invalid: :replace,
                                undef: :replace,
                                replace: ""))
      else
        if @max_size
          utf8_string = @string.byteslice(0, @max_size)
        else
          utf8_string = @string.dup
        end
        utf8_string.force_encoding(Encoding::UTF_8)
        utf8_string.scrub!("")
        utf8_string.gsub!(/\p{Control}+/, "")
        utf8_string
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

    def truncate(string)
      if @max_size and string.bytesize > @max_size
        truncated = string.byteslice(0, @max_size)
        truncated.scrub!("")
        truncated
      else
        string
      end
    end
  end
end
