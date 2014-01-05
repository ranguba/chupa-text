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
        path = fixture_path("hello.txt").to_s
        assert_equal([
                       true,
                       {
                         "mime-type" => "text/plain",
                         "uri"       => path,
                         "size"      => body.bytesize,
                         "texts"     => [
                           {
                             "mime-type" => "text/plain",
                             "uri"       => path,
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
      gz = fixture_path("hello.txt.gz")
      assert_equal([
                     true,
                     {
                       "uri"       => gz.to_s,
                       "mime-type" => "application/x-gzip",
                       "size"      => gz.stat.size,
                       "texts"     => [],
                     },
                   ],
                   run_command("--configuration", conf.to_s,
                               gz.to_s))
    end
  end
end
