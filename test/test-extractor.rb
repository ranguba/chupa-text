# Copyright (C) 2013-2019  Kouhei Sutou <kou@clear-code.com>
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

class TestExtractor < Test::Unit::TestCase
  include Helper

  def setup
    @extractor = ChupaText::Extractor.new
  end

  private
  def fixture_path(*components)
    super("extractor", *components)
  end

  sub_test_case("extract") do
    private
    def extract(data)
      texts = []
      @extractor.extract(data) do |extracted_data|
        texts << extracted_data.body
      end
      texts
    end

    sub_test_case("input") do
      def test_string
        extract(fixture_path("hello.txt").to_s)
      end

      def test_uri
        extract(URI.parse(fixture_path("hello.txt").to_s))
      end

      def test_path
        extract(fixture_path("hello.txt"))
      end
    end

    sub_test_case("no decomposers") do
      def test_text
        data = ChupaText::Data.new
        data.mime_type = "text/plain"
        data.body = "Hello"
        assert_equal(["Hello"], extract(data))
      end

      def test_not_text
        data = ChupaText::Data.new
        data.mime_type = "application/x-javascript"
        data.body = "alert('Hello');"
        assert_equal([], extract(data))
      end
    end

    sub_test_case("use decomposer") do
      class HTMLDecomposer < ChupaText::Decomposer
        def target?(data)
          data.mime_type == "text/html"
        end

        def decompose(data)
          extracted = ChupaText::Data.new
          extracted.mime_type = "text/plain"
          extracted.body = data.body.gsub(/<.+?>/, "")
          sleep(data.timeout * 10) if data.timeout
          yield(extracted)
        end
      end

      def setup
        super
        decomposer = HTMLDecomposer.new({})
        @extractor.add_decomposer(decomposer)
      end

      def test_decompose
        data = ChupaText::Data.new
        data.mime_type = "text/html"
        data.body = "<html><body>Hello</body></html>"
        assert_equal(["Hello"], extract(data))
      end

      def test_timeout
        data = ChupaText::Data.new
        data.mime_type = "text/html"
        data.body = "<html><body>Hello</body></html>"
        data.timeout = 0.0001
        error = ChupaText::TimeoutError.new(data, data.timeout)
        assert_raise(error) do
          extract(data)
        end
      end
    end

    sub_test_case("multi decomposed") do
      class CopyDecomposer < ChupaText::Decomposer
        def target?(data)
          data.mime_type == "text/x-plain"
        end

        def decompose(data)
          copied_data = data.dup
          copied_data.mime_type = "text/plain"
          yield(copied_data.dup)
          yield(copied_data.dup)
        end
      end

      def setup
        super
        decomposer = CopyDecomposer.new({})
        @extractor.add_decomposer(decomposer)
      end

      def test_decompose
        data = ChupaText::Data.new
        data.mime_type = "text/x-plain"
        data.body = "Hello"
        assert_equal(["Hello", "Hello"], extract(data))
      end
    end

    sub_test_case("body") do
      def test_utf8
        data = ChupaText::Data.new
        data.mime_type = "text/plain"
        data.body = "こんにちは"
        assert_equal(["こんにちは"], extract(data))
      end

      def test_utf8_ascii_8bit
        data = ChupaText::Data.new
        data.mime_type = "text/plain"
        data.body = "こんにちは".b
        assert_equal(["こんにちは"], extract(data))
      end

      def test_utf8_broken
        data = ChupaText::Data.new
        data.mime_type = "text/plain"
        data.body = "\x82\x00こんにちは".b
        assert_equal(["こんにちは"], extract(data))
      end

      def test_utf16_le
        data = ChupaText::Data.new
        data.mime_type = "text/plain"
        data.body = "こんにちは".encode("UTF-16LE")
        assert_equal(["こんにちは"], extract(data))
      end

      def test_utf16_le_ascii_8bit
        data = ChupaText::Data.new
        data.mime_type = "text/plain"
        data.body = "\ufeffこんにちは".encode("UTF-16LE").b
        assert_equal(["こんにちは"], extract(data))
      end

      def test_utf16_be
        data = ChupaText::Data.new
        data.mime_type = "text/plain"
        data.body = "こんにちは".encode("UTF-16BE")
        assert_equal(["こんにちは"], extract(data))
      end

      def test_utf16_be_ascii_8bit
        data = ChupaText::Data.new
        data.mime_type = "text/plain"
        data.body = "\ufeffこんにちは".encode("UTF-16BE").b
        assert_equal(["こんにちは"], extract(data))
      end

      def test_utf32_le
        data = ChupaText::Data.new
        data.mime_type = "text/plain"
        data.body = "こんにちは".encode("UTF-32LE")
        assert_equal(["こんにちは"], extract(data))
      end

      def test_utf32_le_ascii_8bit
        data = ChupaText::Data.new
        data.mime_type = "text/plain"
        data.body = "\ufeffこんにちは".encode("UTF-32LE").b
        assert_equal(["こんにちは"], extract(data))
      end

      def test_utf32_be
        data = ChupaText::Data.new
        data.mime_type = "text/plain"
        data.body = "こんにちは".encode("UTF-32BE")
        assert_equal(["こんにちは"], extract(data))
      end

      def test_utf32_be_ascii_8bit
        data = ChupaText::Data.new
        data.mime_type = "text/plain"
        data.body = "\ufeffこんにちは".encode("UTF-32BE").b
        assert_equal(["こんにちは"], extract(data))
      end

      def test_cp932
        data = ChupaText::Data.new
        data.mime_type = "text/plain"
        data.body = "こんにちは".encode("cp932")
        assert_equal(["こんにちは"], extract(data))
      end

      def test_cp932_ascii_8bit
        data = ChupaText::Data.new
        data.mime_type = "text/plain"
        data.body = "こんにちは".encode("cp932").b
        assert_equal(["こんにちは"], extract(data))
      end

      def test_euc_jp
        data = ChupaText::Data.new
        data.mime_type = "text/plain"
        data.body = "こんにちは".encode("euc-jp")
        assert_equal(["こんにちは"], extract(data))
      end

      def test_euc_jp_ascii_8bit
        data = ChupaText::Data.new
        data.mime_type = "text/plain"
        data.body = "こんにちは".encode("euc-jp").b
        assert_equal(["こんにちは"], extract(data))
      end
    end

    sub_test_case("max body size") do
      def test_last_invalid
        @extractor = ChupaText::Extractor.new
        data = ChupaText::Data.new
        data.mime_type = "text/plain"
        data.body = "こん"
        data.max_body_size = 5
        assert_equal(["こ"], extract(data))
      end
    end
  end
end
