# Copyright (C) 2013-2019  Kouhei Sutou <kou@clear-code.com>
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

require "pathname"
require "tempfile"
require "uri"

module Helper
  def fixture_path(*components)
    base_path = Pathname(__FILE__).dirname + "fixture"
    base_path.join(*components)
  end

  def fixture_uri(*components)
    path = fixture_path(*components)
    file_uri(path)
  end

  def file_uri(path)
    URI.parse("file://#{path}")
  end


  class CaptureLogger
    def initialize(output)
      @output = output
    end

    def error(message=nil)
      @output << [:error, message || yield]
    end
  end

  def capture_log
    original_logger = ChupaText.logger
    begin
      output = []
      ChupaText.logger = CaptureLogger.new(output)
      yield
      normalize_log(output)
    ensure
      ChupaText.logger = original_logger
    end
  end

  def normalize_log(log)
    log.collect do |level, message|
      message = message.split("\n", 2)[0]
      [level, message]
    end
  end
end
