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
require "rbconfig"
require "tempfile"
require "uri"
require "webrick"

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

  def capture_log(&block)
    ChupaText::CaptureLogger.capture(&block).collect do |level, message|
      message = message.split("\n", 2)[0]
      [level, message]
    end
  end

  def ruby
    RbConfig.ruby
  end
end
