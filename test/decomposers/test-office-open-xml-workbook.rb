# Copyright (C) 2019-2025  Sutou Kouhei <kou@clear-code.com>
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

    def test_complex_shared_strings
      path = fixture_path("xlsx", "complex-shared-strings.xlsx")
      actual = decompose(path).collect do |data|
        [
          data["index"],
          data["name"],
          data.body,
        ]
      end
      assert_equal([
                     [nil, nil, ""],
                     [
                       0,
                       "新規",
                       "No\t案件番号\t開始日\t期日\tステータス\t備考\n" +
                       "1\t-\t45664\t45672\t対応中\n" +
                       "2\t-\t45664\t45672\t対応中\n" +
                       "3\t-\t45664\t45672\t対応中\n" +
                       "4\t-\t45664\t45666\t対応中\n" +
                       "5\t-\t45664\t45666\t対応中\n" +
                       "6\t-\t45663\t45665\t承認待ち\n" +
                       "7\t-\t45660\t45665\t承認待ち\n" +
                       "8\t-\t45653\t45663\t承認待ち\n" +
                       "9\t-\t45653\t45663\t承認待ち\n" +
                       "10\tPSR2401770\t45652\t45666\t対応中\n",
                     ],
                     [
                       1,
                       "全体",
                       "No\t案件番号\t開始日\t期日\tステータス\n" +
                       "1\tPSR2401564\t45617\t45726\t対応中\n" +
                       "2\tPSR2401194\t45553\t45716\t対応中\n" +
                       "3\t-\t45664\t45672\t対応中\n" +
                       "4\t-\t45664\t45672\t対応中\n" +
                       "5\t-\t45664\t45672\t対応中\n" +
                       "6\t-\t45645\t45672\t対応中\n" +
                       "7\tPSR2401746\t45649\t45671\t対応中\n" +
                       "8\t-\t45640\t45667\t対応中\n" +
                       "9\t-\t45635\t45667\t対応中\n" +
                       "10\tPSR2401605\t45623\t45667\t対応中\n" +
                       "11\t-\t45664\t45666\t対応中\n" +
                       "12\t-\t45664\t45666\t対応中\n" +
                       "13\tPSR2401770\t45652\t45666\t対応中\n" +
                       "14\t-\t45645\t45665\t対応中\n" +
                       "15\tPSR2401609\t45624\t45666\t対応中\n",
                     ],
                     [
                       2,
                       "案件",
                       "No\t案件番号\t開始日\t対応完了時期想定\n" +
                       "1\tPSR2401244\t45561.40347222222\t45744\n" +
                       "2\tPSR2401592\t45621.598611111112\t45698\n" +
                       "3\tPSR2401682\t45638.40902777778\t45688\n" +
                       "4\tPSR2401706\t45643.383333333331\t45671\n" +
                       "5\tPSR2401779\t45653.490277777775\t45671\n" +
                       "6\tPSR2401805\t45664.436805555553\t調整中\n" +
                       "7\tPSR2400677\t45455.588194444441\t45651\t完了\n" +
                       "8\tPSR2401666\t45636.405555555553\t45653\t完了\n" +
                       "9\tPSR2401714\t45644.630555555559\t45652\t完了\n",
                     ],
                     [
                       3,
                       "障害恒久対応・改善対応",
                       "No\t案件番号\t分類\t開始日\t対応完了時期想定\n" +
                       "1\tPSR2401334\t改善対応\t45576.411805555559\t45688\n" +
                       "2\tPSR2401335\t改善対応\t45576.415277777778\t45688\n" +
                       "3\tPSR2401410\t改善対応\t45588.428472222222\t調整中\n" +
                       "4\tPSR2401411\t改善対応\t45588.432638888888\t調整中\n" +
                       "5\tPSR2401718\t障害恒久対応\t45645.386111111111\t45695\n" +
                       "6\tPSR2401807\t障害恒久対応\t45664.546527777777\t調整中\t1/16リリースで調整中\n",
                     ],
                   ],
                   actual)
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
