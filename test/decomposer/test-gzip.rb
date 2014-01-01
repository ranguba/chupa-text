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

class TestGzipDecomposer < Test::Unit::TestCase
  include Helper

  def setup
    @decomposer = ChupaText::GzipDecomposer.new
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
        @data = ChupaText::Data.new
        @data.path = fixture_path("hello.txt.gz")
      end

      def test_path
        assert_equal([fixture_path("hello.txt")],
                     decompose(@data).collect(&:path))
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
        @data = ChupaText::Data.new
        @data.path = fixture_path("hello.tar.gz")
      end

      def test_path
        assert_equal([fixture_path("hello.tar")],
                     decompose(@data).collect(&:path))
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
        @data = ChupaText::Data.new
        @data.path = fixture_path("hello.tgz")
      end

      def test_path
        assert_equal([fixture_path("hello.tar")],
                     decompose(@data).collect(&:path))
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
  end
end
