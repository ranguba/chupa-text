# Copyright (C) 2019  Kouhei Sutou <kou@clear-code.com>
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

class TestDecomposersHTTPServer < Test::Unit::TestCase
  include Helper

  def setup
    ChupaText::Decomposers::HTTPServer.default_url = nil
    setup_server
    setup_data
    setup_decomposer
  end

  def setup_server
    @port = 40080
    @path = "/extraction.json"
    @server_url = "http://127.0.0.1:#{@port}#{@path}"
    logger = WEBrick::Log.new
    logger.level = logger.class::ERROR
    @server = WEBrick::HTTPServer.new(Port: @port,
                                      Logger: logger,
                                      AccessLog: [])
    @response_status = 200
    @server.mount_proc(@path) do |request, response|
      sleep(@timeout * 2) if @timeout
      response.status = @response_status
      response.content_type = "application/json"
      response.body = JSON.generate(@response)
    end
    @server_thread = Thread.new do
      @server.start
    end
  end

  def setup_data
    @input_data = <<-CSV
Hello,World
Ruby,ChupaText
    CSV
    @input_mime_type = "text/csv"
    @input_path = "/tmp/hello.csv"
    @timeout = nil
    @extracted_text = @input_data.gsub(/,/, "\t")
    @extracted_path = @input_path.gsub(/\.csv\z/, ".txt")
    @response = {
      "mime-type" => @input_mime_type,
      "uri" => "file://#{@input_path}",
      "path" => @input_path,
      "size" => @input_data.bytesize,
      "texts" => [
        {
          "mime-type" => "text/plain",
          "uri" => "file://#{@extracted_path}",
          "path" => @extracted_path,
          "size" => @extracted_text.bytesize,
          "source-mime-types" => [
            @input_mime_type,
          ],
          "body" => @extracted_text,
        },
      ],
    }
  end

  def setup_decomposer
    @decomposer = ChupaText::Decomposers::HTTPServer.new(:url => @server_url)
  end

  def teardown
    teardown_server
  end

  def teardown_server
    @server.shutdown
    @server_thread.join
  end

  sub_test_case("decompose") do
    def test_success
      assert_equal([@extracted_text],
                   decompose.collect(&:body))
    end

    def test_not_ok
      @response_status = 404
      messages = capture_log do
        assert_equal([], decompose.collect(&:body))
      end
      assert_equal([
                     [
                       :error,
                       "[decomposer][http-server] " +
                       "Failed to process data in server: " +
                       "<>(#{@input_mime_type}): #{@server_url}: " +
                       "#{@response_status}: Not Found",
                     ],
                   ],
                   messages)
    end

    def test_no_server
      no_server_url = "http://127.0.0.1:2929/extraction.json"
      @decomposer = ChupaText::Decomposers::HTTPServer.new(:url => no_server_url)
      messages = capture_log do
        assert_equal([], decompose.collect(&:body))
      end
      messages = messages.collect do |level, message|
        [level, message.gsub(/Errno::.*\z/, "")]
      end
      assert_equal([
                     [
                       :error,
                       "[decomposer][http-server][connection] " +
                       "Failed to process data in server: " +
                       "#{no_server_url}: ",
                     ],
                   ],
                   messages)
    end

    def test_read_timeout
      @timeout = 0.1
      messages = capture_log do
        assert_equal([], decompose.collect(&:body))
      end
      messages = messages.collect do |level, message|
        [level, message.gsub(/Net::.*\z/, "")]
      end
      assert_equal([
                     [
                       :error,
                       "[decomposer][http-server][timeout] " +
                       "Failed to process data in server: " +
                       "#{@server_url}: ",
                     ],
                   ],
                   messages)
    end

    def test_default_url
      ChupaText::Decomposers::HTTPServer.default_url = @server_url
      @decomposer = ChupaText::Decomposers::HTTPServer.new({})
      assert_equal([@extracted_text],
                   decompose.collect(&:body))
    end

    private
    def decompose
      data = ChupaText::Data.new
      data.path = @input_path
      data.mime_type = @input_mime_type
      data.body = @input_data
      data.timeout = @timeout

      decomposed = []
      @decomposer.decompose(data) do |decomposed_data|
        decomposed << decomposed_data
      end
      decomposed
    end
  end
end
