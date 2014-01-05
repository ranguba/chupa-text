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

module ChupaText
  # Adds shortcut methods for easy to log.
  module Loggable
    private
    def logger
      ChupaText.logger
    end

    def debug(*arguments, &block)
      logger.debug(*arguments, &block)
    end

    def info(*arguments, &block)
      logger.info(*arguments, &block)
    end

    def warn(*arguments, &block)
      logger.warn(*arguments, &block)
    end

    def error(*arguments, &block)
      logger.error(*arguments, &block)
    end

    def fatal(*arguments, &block)
      logger.fatal(*arguments, &block)
    end

    def unknown(*arguments, &block)
      logger.unknown(*arguments, &block)
    end
  end
end
