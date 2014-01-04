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

class TestFileContent < Test::Unit::TestCase
  def setup
    @file = Tempfile.new(["test-file-content", ".txt"])
  end

  def write(string)
    @file.write(string)
    @file.flush
  end

  def test_size
    body = "Hello"
    write(body)
    content = ChupaText::FileContent.new(@file.path)
    assert_equal(body.bytesize, content.size)
  end

  def test_path
    content = ChupaText::FileContent.new(@file.path)
    assert_equal(@file.path, content.path)
  end

  def test_body
    body = "Hello"
    write(body)
    content = ChupaText::FileContent.new(@file.path)
    assert_equal(body, content.body)
  end

  def test_open
    body = "Hello"
    write(body)
    content = ChupaText::FileContent.new(@file.path)
    assert_equal(body, content.open {|file| file.read})
  end
end
