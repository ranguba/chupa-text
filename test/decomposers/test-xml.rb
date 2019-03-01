# Copyright (C) 2013-2019  Kouhei Sutou <kou@clear-code.com>
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

class TestDecomposersXML < Test::Unit::TestCase
  include Helper

  def setup
    @decomposer = ChupaText::Decomposers::XML.new({})
  end

  sub_test_case("decompose") do
    def test_body
      xml = <<-XML
<root>
  Hello
  <sub-element attribute="value">&amp;</sub-element>
  World
</root>
      XML
      text = <<-TEXT

  Hello
  &
  World
      TEXT
      assert_equal([text],
                   decompose(xml).collect(&:body))
    end

    def test_invalid
      messages = capture_log do
        assert_equal([], decompose("<root x=/>"))
      end
      normalized_messages = messages.collect do |level, message|
        [
          level,
          message.gsub(/(ChupaText::SAXParser::ParseError:) .*/,
                       "\\1 ...")
        ]
      end
      assert_equal([
                     [
                       :error,
                       "[decomposer][xml] Failed to parse XML: " +
                       "ChupaText::SAXParser::ParseError: ...",
                     ],
                   ],
                   normalized_messages)
    end

    private
    def decompose(xml)
      data = ChupaText::Data.new
      data.path = "hello.xml"
      data.mime_type = "text/xml"
      data.body = xml

      decomposed = []
      @decomposer.decompose(data) do |decomposed_data|
        decomposed << decomposed_data
      end
      decomposed
    end
  end
end
