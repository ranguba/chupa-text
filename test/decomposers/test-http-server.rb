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
    @port = 40080
    @path = "/extraction.json"
    @server_url = "http://127.0.0.1:#{@port}#{@path}"
    logger = WEBrick::Log.new
    logger.level = logger.class::ERROR
    @server = WEBrick::HTTPServer.new(Port: @port,
                                      Logger: logger,
                                      AccessLog: [])
    @server.mount_proc(@path) do |request, response|
      response["Content-Type"] = "application/json"
      response.body = JSON.generate(@actual)
    end
    @server_thread = Thread.new do
      @server.start
    end
    @decomposer = ChupaText::Decomposers::HTTPServer.new(:url => @server_url)
  end

  def teardown
    @server.shutdown
    @server_thread.join
  end

  sub_test_case("decompose") do
    def test_valid
      csv = <<-CSV
Hello,World
Ruby,ChupaText
      CSV
      extracted = csv.gsub(/,/, "\t")
      @actual = {
        "mime-type" => "text/csv",
        "uri" => "file:///tmp/hello.csv",
        "path" => "/tmp/hello.csv",
        "size" => csv.bytesize,
        "texts" => [
          {
            "mime-type" => "text/plain",
            "uri" => "file:///tmp/hello.txt",
            "path" => "/tmp/hello.txt",
            "size" => extracted.bytesize,
            "source-mime-types" => [
              "text/csv",
            ],
            "body" => extracted,
          },
        ],
      }
      assert_equal([extracted],
                   decompose(csv).collect(&:body))
    end

    private
    def decompose(csv)
      data = ChupaText::Data.new
      data.path = "/tmp/hello.csv"
      data.mime_type = "text/csv"
      data.body = csv

      decomposed = []
      @decomposer.decompose(data) do |decomposed_data|
        decomposed << decomposed_data
      end
      decomposed
    end
  end
end
