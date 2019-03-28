# Copyright (C) 2014-2019  Kouhei Sutou <kou@clear-code.com>
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

class TestExternalCommand < Test::Unit::TestCase
  include Helper

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

  class TestTimeout < self
    def setup
      timeout = ChupaText::ExternalCommand.default_timeout
      soft_timeout = ChupaText::ExternalCommand.default_soft_timeout
      begin
        yield
      ensure
        ChupaText::ExternalCommand.default_timeout = timeout
        ChupaText::ExternalCommand.default_soft_timeout = soft_timeout
      end
    end

    def run_command(options={})
      IO.pipe do |input, output|
        command = create_command(ruby)
        command.run("-e", "puts(Process.pid)",
                    options.merge(spawn_options: {out: output}))
        input.gets.chomp
      end
    end

    def test_option
      pid = nil
      messages = capture_log do
        pid = run_command(timeout: "60s")
      end
      assert_equal([
                     [
                       :info,
                       "[external-command][timeout][use] <60.0s>: <#{pid}>",
                     ]
                   ],
                   messages)
    end

    def test_option_soft_not_use
      pid = nil
      messages = capture_log do
        pid = run_command(timeout: "60s",
                          soft_timeout: "90s")
      end
      assert_equal([
                     [
                       :info,
                       "[external-command][timeout][use] <60.0s>: <#{pid}>",
                     ]
                   ],
                   messages)
    end

    def test_option_soft_use
      pid = nil
      messages = capture_log do
        pid = run_command(timeout: "60s",
                          soft_timeout: "30s")
      end
      assert_equal([
                     [
                       :info,
                       "[external-command][timeout][use] <30.0s>: <#{pid}>",
                     ]
                   ],
                   messages)
    end

    def test_option_soft_only
      pid = nil
      messages = capture_log do
        pid = run_command(soft_timeout: "30s")
      end
      assert_equal([
                     [
                       :info,
                       "[external-command][timeout][use] <30.0s>: <#{pid}>",
                     ]
                   ],
                   messages)
    end

    def test_default
      ChupaText::ExternalCommand.default_timeout = "60s"
      pid = nil
      messages = capture_log do
        pid = run_command
      end
      assert_equal([
                     [
                       :info,
                       "[external-command][timeout][use] <60.0s>: <#{pid}>",
                     ]
                   ],
                   messages)
    end

    def test_default_soft_not_use
      ChupaText::ExternalCommand.default_timeout = "60s"
      ChupaText::ExternalCommand.default_soft_timeout = "90s"
      pid = nil
      messages = capture_log do
        pid = run_command
      end
      assert_equal([
                     [
                       :info,
                       "[external-command][timeout][use] <60.0s>: <#{pid}>",
                     ]
                   ],
                   messages)
    end

    def test_default_soft_use
      ChupaText::ExternalCommand.default_timeout = "60s"
      ChupaText::ExternalCommand.default_soft_timeout = "30s"
      pid = nil
      messages = capture_log do
        pid = run_command
      end
      assert_equal([
                     [
                       :info,
                       "[external-command][timeout][use] <30.0s>: <#{pid}>",
                     ]
                   ],
                   messages)
    end

    def test_default_soft_only
      ChupaText::ExternalCommand.default_timeout = nil
      ChupaText::ExternalCommand.default_soft_timeout = "30s"
      pid = nil
      messages = capture_log do
        pid = run_command
      end
      assert_equal([
                     [
                       :info,
                       "[external-command][timeout][use] <30.0s>: <#{pid}>",
                     ]
                   ],
                   messages)
    end
  end

  class TestLimitCPU < self
    def setup
      limit_cpu = ChupaText::ExternalCommand.default_limit_cpu
      soft_limit_cpu = ChupaText::ExternalCommand.default_soft_limit_cpu
      begin
        yield
      ensure
        ChupaText::ExternalCommand.default_limit_cpu = limit_cpu
        ChupaText::ExternalCommand.default_soft_limit_cpu = soft_limit_cpu
      end
    end

    def run_command(spawn_options={})
      command = create_command(ruby)
      command.run("-e", "true",
                  spawn_options: spawn_options)
    end

    def test_default
      ChupaText::ExternalCommand.default_limit_cpu = "60s"
      messages = capture_log do
        run_command
      end
      soft_limit, hard_limit = Process.getrlimit(Process::RLIMIT_CPU)
      assert_equal([
                     [
                       :info,
                       "[external-command][limit][cpu][set] <60.0s>" +
                       "(soft-limit:#{soft_limit}, hard-limit:#{hard_limit})",
                     ]
                   ],
                   messages)
    end

    def test_default_soft_not_use
      ChupaText::ExternalCommand.default_limit_cpu = "60s"
      ChupaText::ExternalCommand.default_soft_limit_cpu = "90s"
      messages = capture_log do
        run_command
      end
      soft_limit, hard_limit = Process.getrlimit(Process::RLIMIT_CPU)
      assert_equal([
                     [
                       :info,
                       "[external-command][limit][cpu][set] <60.0s>" +
                       "(soft-limit:#{soft_limit}, hard-limit:#{hard_limit})",
                     ]
                   ],
                   messages)
    end

    def test_default_soft_use
      ChupaText::ExternalCommand.default_limit_cpu = "60s"
      ChupaText::ExternalCommand.default_soft_limit_cpu = "30s"
      messages = capture_log do
        run_command
      end
      soft_limit, hard_limit = Process.getrlimit(Process::RLIMIT_CPU)
      assert_equal([
                     [
                       :info,
                       "[external-command][limit][cpu][set] <30.0s>" +
                       "(soft-limit:#{soft_limit}, hard-limit:#{hard_limit})",
                     ]
                   ],
                   messages)
    end

    def test_default_soft_only
      ChupaText::ExternalCommand.default_soft_limit_cpu = "30s"
      messages = capture_log do
        run_command
      end
      soft_limit, hard_limit = Process.getrlimit(Process::RLIMIT_CPU)
      assert_equal([
                     [
                       :info,
                       "[external-command][limit][cpu][set] <30.0s>" +
                       "(soft-limit:#{soft_limit}, hard-limit:#{hard_limit})",
                     ]
                   ],
                   messages)
    end
  end

  class TestLimitAS < self
    def setup
      limit_as = ChupaText::ExternalCommand.default_limit_as
      soft_limit_as = ChupaText::ExternalCommand.default_soft_limit_as
      begin
        yield
      ensure
        ChupaText::ExternalCommand.default_limit_as = limit_as
        ChupaText::ExternalCommand.default_soft_limit_as = soft_limit_as
      end
    end

    def run_command(spawn_options={})
      command = create_command(ruby)
      command.run("-e", "true",
                  spawn_options: spawn_options)
    end

    def test_default
      ChupaText::ExternalCommand.default_limit_as = "100MiB"
      messages = capture_log do
        run_command
      end
      soft_limit, hard_limit = Process.getrlimit(Process::RLIMIT_AS)
      assert_equal([
                     [
                       :info,
                       "[external-command][limit][as][set] " +
                       "<#{100 * 1024 * 1024}>" +
                       "(soft-limit:#{soft_limit}, hard-limit:#{hard_limit})",
                     ]
                   ],
                   messages)
    end

    def test_default_soft_not_use
      ChupaText::ExternalCommand.default_limit_as = "100MiB"
      ChupaText::ExternalCommand.default_soft_limit_as = "150MiB"
      messages = capture_log do
        run_command
      end
      soft_limit, hard_limit = Process.getrlimit(Process::RLIMIT_AS)
      assert_equal([
                     [
                       :info,
                       "[external-command][limit][as][set] " +
                       "<#{100 * 1024 * 1024}>" +
                       "(soft-limit:#{soft_limit}, hard-limit:#{hard_limit})",
                     ]
                   ],
                   messages)
    end

    def test_default_soft_use
      ChupaText::ExternalCommand.default_limit_as = "100MiB"
      ChupaText::ExternalCommand.default_soft_limit_as = "50MiB"
      messages = capture_log do
        run_command
      end
      soft_limit, hard_limit = Process.getrlimit(Process::RLIMIT_AS)
      assert_equal([
                     [
                       :info,
                       "[external-command][limit][as][set] " +
                       "<#{50 * 1024 * 1024}>" +
                       "(soft-limit:#{soft_limit}, hard-limit:#{hard_limit})",
                     ]
                   ],
                   messages)
    end

    def test_default_soft_only
      ChupaText::ExternalCommand.default_soft_limit_as = "50MiB"
      messages = capture_log do
        run_command
      end
      soft_limit, hard_limit = Process.getrlimit(Process::RLIMIT_AS)
      assert_equal([
                     [
                       :info,
                       "[external-command][limit][as][set] " +
                       "<#{50 * 1024 * 1024}>" +
                       "(soft-limit:#{soft_limit}, hard-limit:#{hard_limit})",
                     ]
                   ],
                   messages)
    end
  end
end
