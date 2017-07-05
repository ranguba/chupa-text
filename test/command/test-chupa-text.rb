# Copyright (C) 2013-2017  Kouhei Sutou <kou@clear-code.com>
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

require "socket"

class TestCommandChupaText < Test::Unit::TestCase
  include Helper

  def setup
    setup_io
  end

  def setup_io
    @stdin  = StringIO.new
    @stdout = StringIO.new
  end

  private
  def wrap_io
    @original_stdin  = $stdin
    @original_stdout = $stdout
    $stdin  = @stdin
    $stdout = @stdout
    begin
      yield
    ensure
      $stdin  = @original_stdin
      $stdout = @original_stdout
    end
  end

  def run_command(*arguments)
    succeeded = wrap_io do
      ChupaText::Command::ChupaText.run("--disable-gems", *arguments)
    end
    [succeeded, JSON.parse(@stdout.string)]
  end

  def fixture_path(*components)
    super("command", "chupa-text", *components)
  end

  sub_test_case("output") do
    sub_test_case("file") do
      def test_single
        body = "Hello\n"
        fixture_name = "hello.txt"
        uri = fixture_uri(fixture_name).to_s
        path = fixture_path(fixture_name).to_s
        assert_equal([
                       true,
                       {
                         "mime-type" => "text/plain",
                         "uri"       => uri,
                         "path"      => path,
                         "size"      => body.bytesize,
                         "texts"     => [
                           {
                             "mime-type" => "text/plain",
                             "uri"       => uri,
                             "path"      => path,
                             "size"      => body.bytesize,
                             "body"      => body,
                           },
                         ],
                       },
                     ],
                     run_command(path))
      end
    end

    sub_test_case("URI") do
      def setup
        super
        setup_www_server
      end

      def teardown
        super
        teardown_www_server
      end

      def setup_www_server
        @www_server = TCPServer.new("127.0.0.1", 0)
        _, port, host, = @www_server.addr
        @uri = "http://#{host}:#{port}/"
        @www_server_thread = Thread.new do
          client = @www_server.accept
          loop do
            line = client.gets
            break if line.chomp.empty?
          end
          client.print("HTTP/1.1 200 OK\r\n")
          client.print("Content-Type: text/html\r\n")
          client.print("\r\n")
          client.print(@html)
          client.close
        end
      end

      def teardown_www_server
        @www_server.close
        @www_server_thread.kill
      end

      def test_single
        @html = "<html><body>Hello</body></html>"
        assert_equal([
                       true,
                       {
                         "mime-type" => "text/html",
                         "size"      => @html.bytesize,
                         "uri"       => @uri,
                         "texts"     => [
                           {
                             "mime-type" => "text/html",
                             "size"      => @html.bytesize,
                             "uri"       => @uri,
                             "body"      => @html,
                           },
                         ],
                       },
                     ],
                     run_command(@uri))
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
                         "mime-type" => "text/plain",
                         "size"      => body.bytesize,
                         "texts"     => [
                           {
                             "mime-type" => "text/plain",
                             "size"      => body.bytesize,
                             "body"      => body,
                           },
                         ],
                       },
                     ],
                     run_command)
      end
    end
  end

  sub_test_case("configuration") do
    def test_no_decomposer
      conf = fixture_path("no-decomposer.conf")
      fixture_name = "hello.txt.gz"
      uri = fixture_uri(fixture_name)
      path = fixture_path(fixture_name)
      assert_equal([
                     true,
                     {
                       "uri"       => uri.to_s,
                       "path"      => path.to_s,
                       "mime-type" => "application/x-gzip",
                       "size"      => path.stat.size,
                       "texts"     => [],
                     },
                   ],
                   run_command("--configuration", conf.to_s,
                               path.to_s))
    end
  end

  sub_test_case("extract") do
    def test_csv
      fixture_name = "numbers.csv"
      uri = fixture_uri(fixture_name)
      path = fixture_path(fixture_name)
      assert_equal([
                     true,
                     {
                       "uri"       => uri.to_s,
                       "path"      => path.to_s,
                       "mime-type" => "text/csv",
                       "size"      => path.stat.size,
                       "texts"     => [
                         {
                           "uri"       => uri.to_s,
                           "path"      => path.to_s,
                           "mime-type" => "text/plain",
                           "source-mime-types" => ["text/csv"],
                           "body"      => "1 2 3\n4 5 6\n7 8 9\n",
                           "size"      => 18,
                           "screenshot" => {
                             "mime-type" => "image/svg+xml",
                             "data" => <<-SVG
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg
  xmlns="http://www.w3.org/2000/svg"
  width="100"
  height="100"
  viewBox="0 0 100 100">
  <text
    x="0"
    y="10"
    style="font-size: 10px; white-space: pre-wrap;"
    xml:space="preserve">1 2 3
4 5 6
7 8 9
</text>
</svg>
                             SVG
                           },
                         },
                       ],
                     },
                   ],
                   run_command(path.to_s))
    end
  end
end
