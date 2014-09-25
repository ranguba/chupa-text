# -*- coding: utf-8 -*-
#
# Copyright (C) 2014  Masafumi Yokoyama <myokoym@gmail.com>
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

class TestFormattersJSON < Test::Unit::TestCase
  include Helper

  def setup
    setup_io
    @formatter = ChupaText::Formatters::JSON.new(@stdout)
  end

  def setup_io
    @stdin  = StringIO.new
    @stdout = StringIO.new
  end

  sub_test_case("from_text") do
    def test_ascii
      text = "Sapporo"
      format(text)
      assert(text)
    end

    def test_multibyte
      text = "札幌"
      format(text)
      assert(text)
    end

    private
    def format(text)
      @stdin.write(text)
      @stdin.rewind
      @data = ChupaText::VirtualFileData.new(nil, @stdin)
      @formatter.format_start(@data)
      ChupaText::Extractor.new.extract(@data) do |extracted|
        @formatter.format_extracted(extracted)
      end
      @formatter.format_finish(@data)
    end

    def assert(text)
      assert_equal({
                     "mime-type" => "text/plain",
                     "size"      => text.bytesize,
                     "texts"     => [
                       {
                         "mime-type" => "text/plain",
                         "size"      => text.bytesize,
                         "body"      => text,
                       },
                     ],
                   },
                   JSON.parse(@stdout.string))
    end
  end
end
