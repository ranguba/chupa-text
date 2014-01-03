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

class TestDecomposerRegistry < Test::Unit::TestCase
  class CSVDecomposer < ChupaText::Decomposer
  end

  def setup
    @registry = ChupaText::DecomposerRegistry.new
  end

  def test_register
    assert_equal([], @registry.to_a)
    @registry.register("csv", CSVDecomposer)
    assert_equal([["csv", CSVDecomposer]], @registry.to_a)
  end

  def test_decomposers
    @registry.register("csv", CSVDecomposer)
    assert_equal([CSVDecomposer], @registry.decomposers.collect(&:class))
  end
end
