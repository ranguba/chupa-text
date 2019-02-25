# Copyright (C) 2019  Kouhei Sutou <kou@clear-code.com>
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

class TestDecomposersOpenDocumentSpreadsheet < Test::Unit::TestCase
  include Helper

  def setup
    @decomposer = ChupaText::Decomposers::OpenDocumentSpreadsheet.new({})
  end

  def decompose(path)
    data = ChupaText::InputData.new(path)
    decomposed = []
    @decomposer.decompose(data) do |decomposed_data|
      decomposed << decomposed_data
    end
    decomposed
  end

  sub_test_case("#target_score") do
    def test_extension
      data = ChupaText::Data.new
      data.body = ""
      data.uri = "document.ods"
      assert_equal(-1, @decomposer.target_score(data))
    end

    def test_mime_type
      data = ChupaText::Data.new
      data.mime_type = "application/vnd.oasis.opendocument.spreadsheet"
      assert_equal(-1, @decomposer.target_score(data))
    end
  end

  sub_test_case("#decompose") do
    sub_test_case("attributes") do
      def decompose(attribute_name)
        super(fixture_path("ods", "attributes.ods")).first[attribute_name]
      end

      def test_title
        assert_equal("Title", decompose("title"))
      end

      def test_subject
        assert_equal("Subject", decompose("subject"))
      end

      def test_keywords
        assert_equal(["Keyword1", "Keyword2"], decompose("keywords"))
      end

      def test_created_time
        assert_equal(Time,
                     decompose("created_time").class)
      end

      def test_modified_time
        assert_equal(Time,
                     decompose("modified_time").class)
      end

      def test_generator
        assert_equal("LibreOffice",
                     normalize_generator(decompose("generator")))
      end

      def normalize_generator(generator)
        if generator.start_with?("LibreOffice")
          "LibreOffice"
        else
          generator
        end
      end
    end

    sub_test_case("one sheet") do
      def decompose
        super(fixture_path("ods", "one-sheet.ods")).collect do |data|
          [
            data["index"],
            data["name"],
            data.body,
          ]
        end
      end

      def test_body
        assert_equal([
                       [nil, nil, ""],
                       [
                         0,
                         "Sheet1",
                         "Sheet1 - A1\tSheet1 - B1\n" +
                         "Sheet1 - A2\tSheet1 - B2\n",
                       ],
                     ],
                     decompose)
      end
    end

    sub_test_case("multi sheets") do
      def decompose
        super(fixture_path("ods", "multi-sheets.ods")).collect do |data|
          [
            data["index"],
            data["name"],
            data.body,
          ]
        end
      end

      def test_body
        assert_equal([
                       [nil, nil, ""],
                       [
                         0,
                         "Sheet1",
                         "Sheet1 - A1\tSheet1 - B1\n" +
                         "Sheet1 - A2\tSheet1 - B2\n",
                       ],
                       [
                         1,
                         "Sheet2",
                         "Sheet2 - A1\tSheet2 - B1\n" +
                         "Sheet2 - A2\tSheet2 - B2\n",
                       ],
                       [
                         2,
                         "Sheet3",
                         "Sheet3 - A1\tSheet3 - B1\n" +
                         "Sheet3 - A2\tSheet3 - B2\n",
                       ],
                     ],
                     decompose)
      end
    end
  end
end
