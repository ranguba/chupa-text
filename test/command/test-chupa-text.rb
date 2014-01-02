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

class TestCommandChupaText < Test::Unit::TestCase
  include Helper

  def setup
    setup_io
  end

  def teardown
    teardown_io
  end

  def setup_io
    @original_stdin  = $stdin
    @original_stdout = $stdout
    @stdin  = StringIO.new
    @stdout = StringIO.new
    $stdin  = @stdin
    $stdout = @stdout
  end

  def teardown_io
    $stdin  = @original_stdin
    $stdout = @original_stdout
  end

  private
  def run_command(*arguments)
    succeeded = ChupaText::Command::ChupaText.run(*arguments)
    [succeeded, JSON.parse(@stdout.string)]
  end

  def fixture_path(*components)
    super("command", "chupa-text", *components)
  end

  sub_test_case("output") do
    sub_test_case("file") do
      def test_single
        body = "Hello\n"
        path = fixture_path("hello.txt").to_s
        assert_equal([
                       true,
                       {
                         "content-type" => "text/plain",
                         "path"         => path,
                         "size"         => body.bytesize,
                         "texts"        => [
                           {
                             "content-type" => "text/plain",
                             "path"         => path,
                             "size"         => body.bytesize,
                             "body"         => body,
                           },
                         ],
                       },
                     ],
                     run_command(path))
      end
    end

    sub_test_case("standard input") do
      def test_single
        body = "Hello\n"
        @stdin << "Hello\n"
        @stdin.rewind
        assert_equal([
                       true,
                       {
                         "content-type" => "text/plain",
                         "size"         => body.bytesize,
                         "texts"        => [
                           {
                             "content-type" => "text/plain",
                             "size"         => body.bytesize,
                             "body"         => body,
                           },
                         ],
                       },
                     ],
                     run_command)
      end
    end
  end
end
