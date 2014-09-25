# Copyright (C) 2013  Kouhei Sutou <kou@clear-code.com>
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

    sub_test_case("encoding") do
      def test_ascii8bit_to_default_external
        data = ChupaText::Data.new
        data.mime_type = "text/plain"
        data.body = "Hello".force_encoding("ASCII-8BIT")
        assert_equal(Encoding.default_external,
                     extract(data).first.encoding)
      end
    end
  end
end
