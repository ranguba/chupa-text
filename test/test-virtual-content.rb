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

class TestVirtualContent < Test::Unit::TestCase
  private
  def input(string)
    StringIO.new(string)
  end

  def content(string, original_path=nil)
    ChupaText::VirtualContent.new(input(string), original_path)
  end

  sub_test_case("small data") do
    def setup
      @body = "Hello"
    end

    def test_size
      assert_equal(@body.bytesize, content.size)
    end

    def test_path
      assert_equal(@body, File.read(content.path))
    end

    def test_body
      assert_equal(@body, content.body)
    end

    def test_open
      assert_equal(@body, content.open {|file| file.read})
    end

    private
    def content
      super(@body)
    end
  end

  sub_test_case("large data") do
    def setup
      @body = "X" * (ChupaText::VirtualContent::BUFFER_SIZE + 1)
    end

    def test_size
      assert_equal(@body.bytesize, content.size)
    end

    def test_path
      assert_equal(@body, File.read(content.path))
    end

    def test_body
      assert_equal(@body, content.body)
    end

    def test_open
      assert_equal(@body, content.open {|file| file.read})
    end

    private
    def content
      super(@body)
    end
  end

  sub_test_case("original path") do
    def test_extension
      assert_equal(".txt", File.extname(path("hello.txt")))
    end

    def test_extension_only
      assert_equal(".txt", File.extname(path(".txt")))
    end

    def test_no_extension
      assert_equal("", File.extname(path("hello")))
    end

    def test_nil
      assert_equal("", File.extname(path(nil)))
    end

    private
    def path(original_path)
      content("", original_path).path
    end
  end
end
