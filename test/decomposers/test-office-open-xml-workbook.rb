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

class TestDecomposersOfficeOpenXMLWorkbook < Test::Unit::TestCase
  include Helper

  def setup
    @decomposer = ChupaText::Decomposers::OfficeOpenXMLWorkbook.new({})
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
      data.uri = "workbook.xlsx"
      assert_equal(-1, @decomposer.target_score(data))
    end

    def test_mime_type
      data = ChupaText::Data.new
      data.mime_type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      assert_equal(-1, @decomposer.target_score(data))
    end
  end

  sub_test_case("#decompose") do
    sub_test_case("attributes") do
      def decompose(attribute_name)
        super(fixture_path("xlsx", "attributes.xlsx")).first[attribute_name]
      end

      def test_title
        assert_equal("Title", decompose("title"))
      end

      def test_author
        assert_equal(nil, decompose("author"))
      end

      def test_subject
        assert_equal("Subject", decompose("subject"))
      end

      def test_keywords
        assert_equal("Keyword1 Keyword2", decompose("keywords"))
      end

      def test_created_time
        assert_equal(Time, decompose("created_time").class)
      end

      def test_modified_time
        assert_equal(Time, decompose("modified_time").class)
      end

      def test_application
        assert_equal("LibreOffice",
                     normalize_application(decompose("application")))
      end

      def normalize_application(application)
        if application.start_with?("LibreOffice")
          "LibreOffice"
        else
          application
        end
      end
    end

    sub_test_case("sheets") do
      def decompose(path)
        super(path).collect do |data|
          [
            data["index"],
            data["name"],
            data.body,
          ]
        end
      end

      def test_one_sheet
        assert_equal([
                       [nil, nil, ""],
                       [
                         0,
                         "Sheet1",
                         "Sheet1 - A1\tSheet1 - B1\n" +
                         "Sheet1 - A2\tSheet1 - B2\n",
                       ],
                     ],
                     decompose(fixture_path("xlsx", "one-sheet.xlsx")))
      end

      def test_no_shared_cell
        assert_equal([
                       [nil, nil, ""],
                       [
                         0,
                         "Sheet1",
                         "Sheet1 - A1\tSheet1 - B1\n" +
                         "Sheet1 - A2\tSheet1 - B2\n" +
                         "0.5\t0.5\n",
                       ],
                     ],
                     decompose(fixture_path("xlsx", "not-shared-cell.xlsx")))
      end

      def test_multi_sheets
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
                     decompose(fixture_path("xlsx", "multi-sheets.xlsx")))
      end
    end

    sub_test_case("invalid") do
      def test_empty
        messages = capture_log do
          assert_equal([], decompose(fixture_path("xlsx", "empty.xlsx")))
        end
        assert_equal([
                       [
                         :error,
                         "[decomposer][office-open-xml][workbook] " +
                         "Failed to process zip: " +
                         "Archive::Zip::UnzipError: " +
                         "unable to locate end-of-central-directory record",
                       ],
                     ],
                     messages)
      end
    end
  end
end
