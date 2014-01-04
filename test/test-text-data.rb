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

class TestTextData < Test::Unit::TestCase
  def test_mime_type
    assert_equal("text/plain", text_data("").mime_type)
  end

  def test_body
    body = "Hello"
    assert_equal(body, text_data(body).body)
  end

  def test_size
    body = "Hello"
    assert_equal(body.bytesize, text_data(body).size)
  end

  private
  def text_data(text)
    ChupaText::TextData.new(text)
  end
end
