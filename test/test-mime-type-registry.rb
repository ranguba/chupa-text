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

class TestMIMETypeRegistry < Test::Unit::TestCase
  def setup
    @registry = ChupaText::MIMETypeRegistry.new
  end

  sub_test_case("register") do
    def test_multiple
      @registry.register("csv", "text/csv")
      @registry.register("txt", "text/plain")
      assert_equal("text/csv", @registry.find("csv"))
    end
  end

  sub_test_case("find") do
    def setup
      super
      @registry.register("csv", "text/csv")
    end

    def test_nil
      assert_nil(@registry.find(nil))
    end

    def test_nonexistent
      assert_nil(@registry.find("txt"))
    end

    def test_existent
      assert_equal("text/csv", @registry.find("csv"))
    end
  end
end
