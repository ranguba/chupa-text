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

class TestDecomposersOfficeOpenXMLPresentation < Test::Unit::TestCase
  include Helper

  def setup
    @decomposer = ChupaText::Decomposers::OfficeOpenXMLPresentation.new({})
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
      data.uri = "presentation.pptx"
      assert_equal(-1, @decomposer.target_score(data))
    end

    def test_mime_type
      data = ChupaText::Data.new
      data.mime_type = "application/vnd.openxmlformats-officedocument.presentationml.presentation"
      assert_equal(-1, @decomposer.target_score(data))
    end
  end

  sub_test_case("#decompose") do
    sub_test_case("attributes") do
      def decompose(attribute_name)
        super(fixture_path("pptx", "attributes.pptx")).first[attribute_name]
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

    sub_test_case("slides") do
      def decompose(path)
        super(path).collect do |data|
          [
            data["index"],
            data.body,
          ]
        end
      end

      def test_one_slide
        assert_equal([
                       [nil, ""],
                       [
                         0,
                         "Slide1 title\n" +
                         "Slide1 content\n",
                       ],
                     ],
                     decompose(fixture_path("pptx", "one-slide.pptx")))
      end

      def test_multi_slides
        assert_equal([
                       [nil, ""],
                       [
                         0,
                         "Slide1 title\n" +
                         "Slide1 content\n",
                       ],
                       [
                         1,
                         "Slide2 title\n" +
                         "Slide2 content\n",
                       ],
                       [
                         2,
                         "Slide3 title\n" +
                         "Slide3 content\n",
                       ],
                     ],
                     decompose(fixture_path("pptx", "multi-slides.pptx")))
      end
    end
  end
end
