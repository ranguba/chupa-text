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

class TestDecomposersCSV < Test::Unit::TestCase
  include Helper

  def setup
    @decomposer = ChupaText::Decomposers::CSV.new({})
  end

  sub_test_case("decompose") do
    def test_valid
      csv = <<-CSV
Hello,World
Ruby,ChupaText
      CSV
      assert_equal([csv.gsub(/,/, "\t")],
                   decompose(csv).collect(&:body))
    end

    def test_invalid
      messages = capture_log do
        assert_equal([], decompose("He\x82\x00llo").collect(&:body))
      end
      assert_equal([
                     [
                       :error,
                       "[decomposer][csv] Failed to parse CSV: " +
                       "CSV::InvalidEncodingError: " +
                       "Invalid byte sequence in UTF-8 in line 1.",
                     ],
                   ],
                   messages)
    end

    private
    def decompose(csv)
      data = ChupaText::Data.new
      data.path = "hello.csv"
      data.mime_type = "text/csv"
      data.body = csv

      decomposed = []
      @decomposer.decompose(data) do |decomposed_data|
        decomposed << decomposed_data
      end
      decomposed
    end
  end
end
