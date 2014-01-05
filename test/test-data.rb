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

class TestData < Test::Unit::TestCase
  def setup
    @data = ChupaText::Data.new
    @registry = ChupaText::MIMETypeRegistry.new
    @original_registry = ChupaText::MIMEType.registry
    ChupaText::MIMEType.registry = @registry
  end

  def teardown
    ChupaText::MIMEType.registry = @original_registry
  end

  sub_test_case("mime-type") do
    sub_test_case("guess") do
      sub_test_case("extension") do
        def test_txt
          ChupaText::MIMEType.registry.register("txt", "text/plain")
          assert_equal("text/plain", guess("README.txt"))
        end

        private
        def guess(uri)
          @data.body = "dummy"
          @data.uri = uri
          @data.mime_type
        end
      end

      sub_test_case("body") do
        def test_txt
          body = "Hello"
          body.force_encoding("ASCII-8BIT")
          assert_equal("text/plain", guess(body))
        end

        private
        def guess(body)
          @data.body = body
          @data.mime_type
        end
      end
    end

    sub_test_case("text?") do
      def test_text_plain
        @data.mime_type = "text/plain"
        assert_true(@data.text?)
      end

      def test_text_html
        @data.mime_type = "text/html"
        assert_true(@data.text?)
      end

      def test_application_xhtml_xml
        @data.mime_type = "application/xhtml+xml"
        assert_false(@data.text?)
      end
    end

    sub_test_case("text_plain?") do
      def test_text_plain
        @data.mime_type = "text/plain"
        assert_true(@data.text_plain?)
      end

      def test_text_html
        @data.mime_type = "text/html"
        assert_false(@data.text_plain?)
      end

      def test_application_xhtml_xml
        @data.mime_type = "application/xhtml+xml"
        assert_false(@data.text_plain?)
      end
    end
  end

  sub_test_case("extension") do
    def test_no_uri
      assert_nil(extension(nil))
    end

    def test_lower_case
      assert_equal("md", extension("README.md"))
    end

    def test_upper_case
      assert_equal("md", extension("README.MD"))
    end

    def test_mixed_case
      assert_equal("md", extension("README.mD"))
    end

    private
    def extension(uri)
      @data.body = "dummy"
      @data.uri = uri
      @data.extension
    end
  end
end
