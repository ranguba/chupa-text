# Copyright (C) 2017  Kouhei Sutou <kou@clear-code.com>
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

class TestMIMEFormatter < Test::Unit::TestCase
  def setup
    @output = StringIO.new
    @formatter = ChupaText::Formatters::MIME.new(@output)
  end

  def format(data, extracted_data)
    @formatter.format_start(data)
    extracted_data.each do |extracted_datum|
      @formatter.format_extracted(extracted_datum)
    end
    @formatter.format_finish(data)
    @output.string
  end

  def test_text
    data = ChupaText::TextData.new("Hello")
    data.uri = URI.parse("file:///tmp/hello.txt")
    assert_equal(<<-MIME.gsub(/\n/, "\r\n"), format(data, [data]))
MIME-Version: 1.0
mime-type: text/plain
uri: file:///tmp/hello.txt
path: /tmp/hello.txt
size: 5
Content-Type: multipart/mixed; boundary=a21ff2fc51d8d8c8af3e7ccb974e34b0368e2891

--a21ff2fc51d8d8c8af3e7ccb974e34b0368e2891
mime-type: text/plain
uri: file:///tmp/hello.txt
path: /tmp/hello.txt
size: 5

Hello
--a21ff2fc51d8d8c8af3e7ccb974e34b0368e2891--
    MIME
  end

  def test_texts
    data = ChupaText::Data.new
    data.uri = URI.parse("file:///tmp/hello-world.zip")
    data1 = ChupaText::TextData.new("Hello")
    data1.uri = URI.parse("file:///tmp/hello.txt")
    data2 = ChupaText::TextData.new("World")
    data2.uri = URI.parse("file:///tmp/world.txt")
    assert_equal(<<-MIME.gsub(/\n/, "\r\n"), format(data, [data1, data2]))
MIME-Version: 1.0
mime-type: application/zip
uri: file:///tmp/hello-world.zip
path: /tmp/hello-world.zip
Content-Type: multipart/mixed; boundary=e53a82b45aee7c6a07ea51dcf930118dedf7da4d

--e53a82b45aee7c6a07ea51dcf930118dedf7da4d
mime-type: text/plain
uri: file:///tmp/hello.txt
path: /tmp/hello.txt
size: 5

Hello
--e53a82b45aee7c6a07ea51dcf930118dedf7da4d
mime-type: text/plain
uri: file:///tmp/world.txt
path: /tmp/world.txt
size: 5

World
--e53a82b45aee7c6a07ea51dcf930118dedf7da4d--
    MIME
  end
end
