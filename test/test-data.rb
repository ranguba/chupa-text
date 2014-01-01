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

class TestData < Test::Unit::TestCase
  def setup
    @data = ChupaText::Data.new
    ChupaText::ContentType.registory.clear
  end

  sub_test_case("content-type") do
    sub_test_case("guess") do
      private
      def guess(path)
        @data.path = path
        @data.content_type
      end

      sub_test_case("extension") do
        def test_txt
          ChupaText::ContentType.registory.register("txt", "text/plain")
          assert_equal("text/plain", guess("README.txt"))
        end
      end
    end
  end

  sub_test_case("extension") do
    def test_no_path
      assert_nil(extension(nil))
    end

    def test_lower_case
      assert_equal("md", extension("README.md"))
    end

    def test_upper_case
      assert_equal("md", extension("README.MD"))
    end

    def test_mixed_case
      assert_equal("md", extension("README.mD"))
    end

    private
    def extension(path)
      @data.path = path
      @data.extension
    end
  end
end
