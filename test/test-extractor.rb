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
  def setup
    @extractor = ChupaText::Extractor.new
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

    sub_test_case("no decomposers") do
      def test_text
        data = ChupaText::Data.new
        data.content_type = "text/plain"
        data.body = "Hello"
        assert_equal(["Hello"], extract(data))
      end

      def test_not_text
        data = ChupaText::Data.new
        data.content_type = "text/html"
        data.body = "<html><body>Hello</body></html>"
        assert_equal([], extract(data))
      end
    end

    sub_test_case("use decomposer") do
      class HTMLDecomposer < ChupaText::Decomposer
        def target?(data)
          data.content_type == "text/html"
        end

        def decompose(data)
          extracted = ChupaText::Data.new
          extracted.content_type = "text/plain"
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
        data.content_type = "text/html"
        data.body = "<html><body>Hello</body></html>"
        assert_equal(["Hello"], extract(data))
      end
    end

    sub_test_case("multi decomposed") do
      class CopyDecomposer < ChupaText::Decomposer
        def target?(data)
          data["copied"].nil?
        end

        def decompose(data)
          copied_data = data.dup
          copied_data["copied"] = true
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
        data.content_type = "text/plain"
        data.body = "Hello"
        assert_equal(["Hello", "Hello"], extract(data))
      end
    end
  end
end
