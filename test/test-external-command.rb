# Copyright (C) 2014  Kouhei Sutou <kou@clear-code.com>
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

require "rbconfig"

class TestExternalCommand < Test::Unit::TestCase
  def ruby
    RbConfig.ruby
  end

  def create_command(command)
    ChupaText::ExternalCommand.new(command)
  end

  class TestRun < self
    def run_command(command, *arguments)
      create_command(command).run(*arguments)
    end

    def test_success
      assert_true(run_command(ruby, "-e", "true"))
    end

    def test_failure
      error = Tempfile.new("error")
      spawn_options = {
        :err => error.path,
      }
      assert_false(run_command(ruby,
                               "-e", "raise 'XXX'",
                               :spawn_options => spawn_options))
    end
  end

  class TestExist < self
    def setup
      @original_path = ENV["PATH"]
    end

    def teardown
      ENV["PATH"] = @original_path
    end

    def exist?(command)
      create_command(command).exist?
    end

    def test_exist_absolete_path
      assert_true(exist?(ruby))
    end

    def test_exist_in_path
      ruby_dir, ruby_base_name = File.split(ruby)
      ENV["PATH"] += "#{File::PATH_SEPARATOR}#{ruby_dir}"
      assert_true(exist?(ruby_base_name))
    end

    def test_not_executable
      assert_false(exist?(__FILE__))
    end

    def test_not_exist
      assert_false(exist?("nonexistent"))
    end
  end
end
