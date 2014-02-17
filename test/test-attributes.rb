# Copyright (C) 2014  Kouhei Sutou <kou@clear-code.com>
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

class TestAttributes < Test::Unit::TestCase
  def setup
    @attributes = ChupaText::Attributes.new
  end

  sub_test_case("title") do
    def test_accessor
      assert_nil(@attributes.title)
      @attributes.title = "Title"
      assert_equal("Title", @attributes.title)
    end
  end

  sub_test_case("author") do
    def test_accessor
      assert_nil(@attributes.author)
      @attributes.author = "Alice"
      assert_equal("Alice", @attributes.author)
    end
  end

  sub_test_case("encoding") do
    def test_string
      @attributes.encoding = "UTF-8"
      assert_equal(Encoding::UTF_8, @attributes.encoding)
    end

    def test_encoding
      @attributes.encoding = Encoding::UTF_8
      assert_equal(Encoding::UTF_8, @attributes.encoding)
    end

    def test_nil
      @attributes.encoding = nil
      assert_nil(@attributes.encoding)
    end
  end

  sub_test_case("created_time") do
    def test_string
      @attributes.created_time = "2014-02-17T23:14:30+09:00"
      assert_equal(Time.parse("2014-02-17T23:14:30+09:00"),
                   @attributes.created_time)
    end

    def test_integer
      @attributes.created_time = 1392646470
      assert_equal(Time.parse("2014-02-17T23:14:30+09:00"),
                   @attributes.created_time)
    end

    def test_time
      @attributes.created_time = Time.parse("2014-02-17T23:14:30+09:00")
      assert_equal(Time.parse("2014-02-17T23:14:30+09:00"),
                   @attributes.created_time)
    end

    def test_nil
      @attributes.created_time = nil
      assert_nil(@attributes.created_time)
    end
  end

  sub_test_case("modified_time") do
    def test_string
      @attributes.modified_time = "2014-02-17T23:14:30+09:00"
      assert_equal(Time.parse("2014-02-17T23:14:30+09:00"),
                   @attributes.modified_time)
    end

    def test_integer
      @attributes.modified_time = 1392646470
      assert_equal(Time.parse("2014-02-17T23:14:30+09:00"),
                   @attributes.modified_time)
    end

    def test_time
      @attributes.modified_time = Time.parse("2014-02-17T23:14:30+09:00")
      assert_equal(Time.parse("2014-02-17T23:14:30+09:00"),
                   @attributes.modified_time)
    end

    def test_nil
      @attributes.modified_time = nil
      assert_nil(@attributes.modified_time)
    end
  end
end
