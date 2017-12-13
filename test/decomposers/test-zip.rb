# Copyright (C) 2017  Kouhei Sutou <kou@clear-code.com>
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

class TestDecomposersZip < Test::Unit::TestCase
  include Helper

  def setup
    @decomposer = ChupaText::Decomposers::Zip.new({})
  end

  private
  def fixture_path(*components)
    super("zip", *components)
  end

  sub_test_case("decompose") do
    def decompose(data_path)
      data = ChupaText::InputData.new(data_path)
      decomposed = []
      @decomposer.decompose(data) do |decomposed_data|
        decomposed << {
          :uri    => decomposed_data.uri.to_s,
          :body   => decomposed_data.body,
          :source => decomposed_data.source.uri.to_s,
        }
      end
      decomposed
    end

    test("multiple") do
      data_path = Pathname.new(fixture_path("hello.zip"))
      base_path = data_path.sub_ext("")
      assert_equal([
                     {
                       :uri    => file_uri("#{base_path}/hello.txt").to_s,
                       :body   => "Hello!\n",
                       :source => file_uri(data_path).to_s,
                     },
                     {
                       :uri    => file_uri("#{base_path}/hello.csv").to_s,
                       :body   => "Hello,World\n",
                       :source => file_uri(data_path).to_s,
                     },
                     {
                       :uri    => file_uri("#{base_path}/hello/world.txt").to_s,
                       :body   => "World!\n",
                       :source => file_uri(data_path).to_s,
                     },
                   ],
                   decompose(data_path))
    end

    sub_test_case("encrypted") do
      test("without password") do
        data_path = Pathname.new(fixture_path("password.zip"))
        data = ChupaText::InputData.new(data_path)
        assert_raise(ChupaText::EncryptedError.new(data)) do
          @decomposer.decompose(data)
        end
      end

      test("with password") do
        omit("password is 'password'")
        data_path = Pathname.new(fixture_path("password.zip"))
        base_path = data_path.sub_ext("")
        assert_equal([
                       {
                         :uri    => "file:#{base_path}/hello.txt",
                         :body   => "Hello!\n",
                         :source => "file:#{data_path}",
                       },
                       {
                         :uri    => "file:#{base_path}/hello.csv",
                         :body   => "Hello,World\n",
                         :source => "file:#{data_path}",
                       },
                       {
                         :uri    => "file:#{base_path}/hello/world.txt",
                         :body   => "World!\n",
                         :source => "file:#{data_path}",
                       },
                     ],
                     decompose(data_path))
      end
    end
  end
end
