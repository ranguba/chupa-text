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

  def test_size
    body = "Hello"
    assert_equal(body.bytesize, content(body).size)
  end

  def test_path
    assert_equal(@file.path, content.path)
  end

  def test_body
    body = "Hello"
    assert_equal(body, content(body).body)
  end

  def test_open
    body = "Hello"
    assert_equal(body, content(body).open {|file| file.read})
  end

  private
  def write(string)
    @file.write(string)
    @file.flush
  end

  def content(string=nil)
    write(string) if string
    ChupaText::FileContent.new(@file.path)
  end
end
