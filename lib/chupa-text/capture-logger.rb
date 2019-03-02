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

module ChupaText
  class CaptureLogger
    class << self
      def capture
        original_logger = ChupaText.logger
        begin
          output = []
          ChupaText.logger = new(output)
          yield
          output
        ensure
          ChupaText.logger = original_logger
        end
      end
    end

    def initialize(output)
      @output = output
    end

    def debug(message=nil)
      @output << [:debu, message || yield]
    end

    def info(message=nil)
      @output << [:info, message || yield]
    end

    def warn(message=nil)
      @output << [:warn, message || yield]
    end

    def error(message=nil)
      @output << [:error, message || yield]
    end

    def fatal(message=nil)
      @output << [:fatal, message || yield]
    end
  end
end
