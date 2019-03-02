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

require "chupa-text/version"

require "chupa-text/error"

require "chupa-text/size-parser"
require "chupa-text/default-logger"
require "chupa-text/logger"

require "chupa-text/loggable"
require "chupa-text/unzippable"

require "chupa-text/configuration"
require "chupa-text/configuration-loader"
require "chupa-text/mime-type"
require "chupa-text/mime-type-registry"

require "chupa-text/external-command"

require "chupa-text/decomposer"
require "chupa-text/decomposer-registry"
require "chupa-text/decomposers"

require "chupa-text/extractor"
require "chupa-text/formatters"

require "chupa-text/file-content"
require "chupa-text/virtual-content"

require "chupa-text/screenshot"

require "chupa-text/attributes"
require "chupa-text/data"
require "chupa-text/input-data"
require "chupa-text/virtual-file-data"
require "chupa-text/text-data"

require "chupa-text/command"
