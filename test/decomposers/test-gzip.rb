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

class TestDecomposersGzip < Test::Unit::TestCase
  include Helper

  def setup
    @decomposer = ChupaText::Decomposers::Gzip.new({})
  end

  private
  def fixture_path(*components)
    super("gzip", *components)
  end

  sub_test_case("decompose") do
    def decompose(data)
      decomposed = []
      @decomposer.decompose(data) do |decomposed_data|
        decomposed << decomposed_data
      end
      decomposed
    end

    sub_test_case("gz") do
      def setup
        super
        @data = ChupaText::InputData.new(fixture_path("hello.txt.gz"))
      end

      def test_uri
        assert_equal([fixture_uri("hello.txt")],
                     decompose(@data).collect(&:uri))
      end

      def test_body
        assert_equal(["Hello\n"],
                     decompose(@data).collect(&:body))
      end

      def test_source
        assert_equal([@data],
                     decompose(@data).collect(&:source))
      end
    end

    sub_test_case("tar.gz") do
      def setup
        super
        @data = ChupaText::InputData.new(fixture_path("hello.tar.gz"))
      end

      def test_uri
        assert_equal([fixture_uri("hello.tar")],
                     decompose(@data).collect(&:uri))
      end

      def test_body
        tar_magic = "ustar"
        magics = decompose(@data).collect do |decomposed|
          decomposed.body[257, tar_magic.bytesize]
        end
        assert_equal([tar_magic],
                     magics)
      end

      def test_source
        assert_equal([@data],
                     decompose(@data).collect(&:source))
      end
    end

    sub_test_case("tgz") do
      def setup
        super
        @data = ChupaText::InputData.new(fixture_path("hello.tgz"))
      end

      def test_uri
        assert_equal([fixture_uri("hello.tar")],
                     decompose(@data).collect(&:uri))
      end

      def test_body
        tar_magic = "ustar"
        magics = decompose(@data).collect do |decomposed|
          decomposed.body[257, tar_magic.bytesize]
        end
        assert_equal([tar_magic],
                     magics)
      end

      def test_source
        assert_equal([@data],
                     decompose(@data).collect(&:source))
      end
    end

    def test_invalid
      data = ChupaText::Data.new
      data.body = "Hello"
      data.size = data.body.bytesize
      data.mime_type = "application/gzip"
      messages = capture_log do
        assert_equal([], decompose(data).collect(&:body))
      end
      assert_equal([
                     [
                       :error,
                       "[decomposer][gzip] Failed to uncompress: " +
                       "Zlib::GzipFile::Error: not in gzip format",
                     ],
                   ],
                   messages)
    end
  end
end
