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

class TestDecomposersTar < Test::Unit::TestCase
  include Helper

  def setup
    @decomposer = ChupaText::Decomposers::Tar.new({})
  end

  private
  def fixture_path(*components)
    super("tar", *components)
  end

  sub_test_case("decompose") do
    def decompose(data)
      decomposed = []
      @decomposer.decompose(data) do |decomposed_data|
        decomposed << {
          :uri    => decomposed_data.uri.to_s,
          :body   => decomposed_data.body,
          :source => decomposed_data.source.uri.to_s,
        }
      end
      decomposed
    end

    sub_test_case("top-level") do
      def setup
        super
        @data = ChupaText::Data.new
        @data.uri = fixture_path("top-level.tar")
      end

      def test_decompose
        assert_equal([
                       {
                         :uri    => "top-level.txt",
                         :body   => "top level\n",
                         :source => @data.uri.to_s,
                       },
                     ],
                     decompose(@data))
      end
    end

    sub_test_case("directory") do
      def setup
        super
        @data = ChupaText::Data.new
        @data.uri = fixture_path("directory.tar")
      end

      def test_decompose
        assert_equal([
                       {
                         :uri    => "directory/hello.txt",
                         :body   => "Hello in directory\n",
                         :source => @data.uri.to_s,
                       },
                     ],
                     decompose(@data))
      end
    end
  end
end
