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
  include Helper

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
    data.uri = URI.parse("http://example.com/hello.txt")
    assert_equal(<<-MIME.gsub(/\n/, "\r\n"), format(data, [data]))
MIME-Version: 1.0
mime-type: text/plain
uri: http://example.com/hello.txt
size: 5
Content-Type: multipart/mixed; boundary=e37eebaf33e7c817702a3ceb4b86260a936b2503

--e37eebaf33e7c817702a3ceb4b86260a936b2503
mime-type: text/plain
uri: http://example.com/hello.txt
size: 5

Hello
--e37eebaf33e7c817702a3ceb4b86260a936b2503--
    MIME
  end

  def test_texts
    data = ChupaText::Data.new
    data.uri = URI.parse("http://example.com/hello-world.zip")
    data1 = ChupaText::TextData.new("Hello")
    data1.uri = URI.parse("http://example.com/hello-world.zip/hello.txt")
    data2 = ChupaText::TextData.new("World")
    data2.uri = URI.parse("http://example.com/hello-world.zip/world.txt")
    assert_equal(<<-MIME.gsub(/\n/, "\r\n"), format(data, [data1, data2]))
MIME-Version: 1.0
mime-type: application/zip
uri: http://example.com/hello-world.zip
Content-Type: multipart/mixed; boundary=2982df00a82c74bdb9d9c6dd5bf007d435c352c9

--2982df00a82c74bdb9d9c6dd5bf007d435c352c9
mime-type: text/plain
uri: http://example.com/hello-world.zip/hello.txt
size: 5

Hello
--2982df00a82c74bdb9d9c6dd5bf007d435c352c9
mime-type: text/plain
uri: http://example.com/hello-world.zip/world.txt
size: 5

World
--2982df00a82c74bdb9d9c6dd5bf007d435c352c9--
    MIME
  end
end
