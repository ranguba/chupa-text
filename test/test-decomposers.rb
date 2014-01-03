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

class TestDecomposers < Test::Unit::TestCase
  class CSVDecomposer < ChupaText::Decomposer
  end

  def setup
    @registry = ChupaText::DecomposerRegistry.new
    @registry.register("csv", CSVDecomposer)
    @configuration = ChupaText::Configuration.new
  end

  sub_test_case("create") do
    def test_default
      decomposers = create
      assert_equal([CSVDecomposer], decomposers.collect(&:class))
    end

    def test_no_match
      @configuration.decomposer.names = []
      decomposers = create
      assert_equal([], decomposers.collect(&:class))
    end

    def test_glob
      @configuration.decomposer.names = ["*sv"]
      decomposers = create
      assert_equal([CSVDecomposer], decomposers.collect(&:class))
    end

    def test_ext_glob
      unless File.const_defined?(:FNM_EXTGLOB)
        omit("File::FNM_EXTGLOB is required")
      end
      @configuration.decomposer.names = ["{a,b,c}sv"]
      decomposers = create
      assert_equal([CSVDecomposer], decomposers.collect(&:class))
    end

    private
    def create
      ChupaText::Decomposers.create(@registry, @configuration.decomposer)
    end
  end
end
