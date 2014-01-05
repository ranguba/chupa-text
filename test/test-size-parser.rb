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

class TestSizeParser < Test::Unit::TestCase
  private
  def parse(value)
    ChupaText::SizeParser.parse(value)
  end

  sub_test_case("unit") do
    def test_terabyte
      assert_equal(1024 ** 4, parse("1TB"))
    end

    def test_tera
      assert_equal(1024 ** 4, parse("1T"))
    end

    def test_gigabyte
      assert_equal(1024 ** 3, parse("1GB"))
    end

    def test_giga
      assert_equal(1024 ** 3, parse("1G"))
    end

    def test_megabyte
      assert_equal(1024 ** 2, parse("1MB"))
    end

    def test_mega
      assert_equal(1024 ** 2, parse("1M"))
    end

    def test_kilobyte
      assert_equal(1024 ** 1, parse("1KB"))
    end

    def test_kilo
      assert_equal(1024 ** 1, parse("1K"))
    end

    def test_byte
      assert_equal(1, parse("1B"))
    end
  end

  sub_test_case("float") do
    def test_with_unit
      assert_equal(1024 + 512, parse("1.5KB"))
    end

    def test_without_unit
      assert_equal(2, parse("1.5"))
    end
  end

  sub_test_case("invalid") do
    def test_unknwon_unit
      size = "1.5PB"
      assert_raise(ChupaText::SizeParser::InvalidSizeError.new(size)) do
        parse(size)
      end
    end
  end
end
