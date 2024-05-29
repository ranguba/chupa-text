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

class TestDefaultLogger < Test::Unit::TestCase
  def setup
    @env = {}
    ENV.each do |key, value|
      @env[key] = value
    end
  end

  def teardown
    ENV.replace(@env)
  end

  private
  def default_n_generations
    7
  end

  def default_max_size
    1024 * 1024
  end

  sub_test_case("output") do
    def output(value)
      ENV["CHUPA_TEXT_LOG_OUTPUT"] = value
      logger = ChupaText::DefaultLogger.new
      device = logger.instance_variable_get(:@logdev)
      dev = device.dev
      logger.close if dev.class == File
      dev
    end

    def test_minus
      assert_equal(STDOUT, output("-"))
    end

    def test_plus
      assert_equal(STDERR, output("+"))
    end

    def test_string
      Tempfile.create("chupa-text-default-logger-output") do |file|
        assert_equal(file.path, output(file.path).path)
      end
    end

    def test_default
      assert_equal(STDERR, output(nil))
    end
  end

  sub_test_case("rotation period") do
    def rotation_period(value)
      Tempfile.create("chupa-text-default-logger-output") do |file|
        ENV["CHUPA_TEXT_LOG_OUTPUT"] = file.path
        ENV["CHUPA_TEXT_LOG_ROTATION_PERIOD"] = value
        logger = ChupaText::DefaultLogger.new
        logger.close
        device = logger.instance_variable_get(:@logdev)
        device.instance_variable_get(:@shift_age)
      end
    end

    def test_daily
      assert_equal("daily", rotation_period("daily"))
    end

    def test_weekly
      assert_equal("weekly", rotation_period("weekly"))
    end

    def test_monthly
      assert_equal("monthly", rotation_period("monthly"))
    end

    def test_default
      assert_equal(default_n_generations, rotation_period(nil))
    end

    def test_invalid
      assert_equal(default_n_generations, rotation_period(nil))
    end
  end

  sub_test_case("N generation") do
    def n_generations(value)
      Tempfile.create("chupa-text-default-logger-output") do |file|
        ENV["CHUPA_TEXT_LOG_OUTPUT"] = file.path
        ENV["CHUPA_TEXT_LOG_N_GENERATIONS"] = value
        logger = ChupaText::DefaultLogger.new
        logger.close
        device = logger.instance_variable_get(:@logdev)
        device.instance_variable_get(:@shift_age)
      end
    end

    def test_integer
      assert_equal(29, n_generations("29"))
    end

    def test_default
      assert_equal(default_n_generations, n_generations(nil))
    end

    def test_invalid
      assert_equal(default_n_generations, n_generations("2.9"))
    end
  end

  sub_test_case("max size") do
    def max_size(value)
      Tempfile.create("chupa-text-default-logger-output") do |file|
        ENV["CHUPA_TEXT_LOG_OUTPUT"] = file.path
        ENV["CHUPA_TEXT_LOG_MAX_SIZE"] = value
        logger = ChupaText::DefaultLogger.new
        logger.close
        device = logger.instance_variable_get(:@logdev)
        device.instance_variable_get(:@shift_size)
      end
    end

    def test_unit
      assert_equal(1024, max_size("1KB"))
    end

    def test_value_only
      assert_equal(1024, max_size("1024"))
    end

    def test_default
      assert_equal(default_max_size, max_size(nil))
    end

    def test_invalid
      assert_equal(default_max_size, max_size("max-size"))
    end
  end

  sub_test_case("level") do
    def level(value)
      ENV["CHUPA_TEXT_LOG_LEVEL"] = value
      logger = ChupaText::DefaultLogger.new
      logger.level
    end

    def test_debug
      assert_equal(Logger::DEBUG, level("debug"))
    end

    def test_info
      assert_equal(Logger::INFO, level("info"))
    end

    def test_warn
      assert_equal(Logger::WARN, level("warn"))
    end

    def test_error
      assert_equal(Logger::ERROR, level("error"))
    end

    def test_fatal
      assert_equal(Logger::FATAL, level("fatal"))
    end

    def test_unknown
      assert_equal(Logger::UNKNOWN, level("unknown"))
    end

    def test_default
      assert_equal(Logger::INFO, level(nil))
    end

    def test_invalid
      assert_equal(Logger::INFO, level("invalid"))
    end
  end
end
