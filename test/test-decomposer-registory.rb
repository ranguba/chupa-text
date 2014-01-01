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

class TestDecomposerRegistory < Test::Unit::TestCase
  class CSVDecomposer < ChupaText::Decomposer
  end

  def setup
    @registory = ChupaText::DecomposerRegistory.new
  end

  def test_register
    assert_equal([], @registory.to_a)
    @registory.register(CSVDecomposer)
    assert_equal([CSVDecomposer], @registory.to_a)
  end

  def test_decomposers
    @registory.register(CSVDecomposer)
    assert_equal([CSVDecomposer], @registory.decomposers.collect(&:class))
  end
end
