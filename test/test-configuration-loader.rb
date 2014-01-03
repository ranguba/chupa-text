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

class TestConfiguration < Test::Unit::TestCase
  def setup
    @configuration = ChupaText::Configuration.new
    @loader = ChupaText::ConfigurationLoader.new(@configuration)
  end

  private
  def load(content)
    file = Tempfile.new("chupa-text")
    file.print(content)
    file.flush
    @loader.load(file.path)
    file
  end

  sub_test_case("decomposer") do
    def test_names
      load(<<-CONFIGURATION)
decomposer.names = ["tar", "zip"]
      CONFIGURATION
      assert_equal(["tar", "zip"], @configuration.decomposer.names)
    end

    def test_option
      load(<<-CONFIGURATION)
decomposer.tar = {
  :omit_size => true
}
      CONFIGURATION
      assert_equal({
                     "tar" => {
                       :omit_size => true,
                     },
                   },
                   @configuration.decomposer.options)
    end
  end
end
