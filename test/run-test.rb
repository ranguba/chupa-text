#!/usr/bin/env ruby
#
# Copyright (C) 2013-2020  Sutou Kouhei <kou@clear-code.com>
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

$VERBOSE = true

require "pathname"

require "test-unit"

base_dir = Pathname(__FILE__).dirname.parent
lib_dir = base_dir + "lib"
test_dir = base_dir + "test"

$LOAD_PATH.unshift(lib_dir.to_s)

require "chupa-text"

ChupaText::Decomposers.load

require_relative "helper"

ENV["TEST_UNIT_MAX_DIFF_TARGET_STRING_SIZE"] = "1_000_000"
exit(Test::Unit::AutoRunner.run(true, test_dir.to_s))
