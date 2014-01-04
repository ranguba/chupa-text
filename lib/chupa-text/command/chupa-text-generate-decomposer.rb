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

require "optparse"
require "etc"

module ChupaText
  module Command
    class ChupaTextGenerateDecomposer
      class << self
        def run(*arguments)
          command = new
          command.run(*arguments)
        end
      end

      def initialize
        @name = nil
        @extensions = nil
        @mime_types = nil
        @author = guess_author
        @email = guess_email
        @license = lgplv2_1_or_later_license
        @parser = create_option_parser
      end

      def run(*arguments)
        begin
          @parser.parse!(arguments)
        rescue OptionParser::ParseError
          puts($!.message)
          return false
        end
        read_missing_parameters
        generate
        true
      end

      private
      def guess_author
        author = guess_author_from_password_entry
        author ||= ENV["USERNAME"]
        author
      end

      def guess_author_from_password_entry
        password_entry = find_password_entry
        return nil if password_entry.nil?

        author = password_entry.gecos.split(/,/).first.strip
        author = nil if author.empty?
        author
      end

      def find_password_entry
        Etc.getpwuid
      rescue ArgumentError
        nil
      end

      def guess_email
        ENV["EMAIL"]
      end

      def lgplv2_1_or_later_license
        "LGPLv2.1 or later"
      end

      def create_option_parser
        parser = OptionParser.new
        parser.version = VERSION
        parser.on("--name=NAME",
                  "Decomposer name",
                  "(e.g.: html)") do |name|
          @name = name
        end
        parser.on("--extensions=EXTENSION1,EXTENSION2,...", Array,
                  "Target file extensions",
                  "(e.g.: htm,html,xhtml)") do |extensions|
          @extensions = extensions
        end
        parser.on("--mime-types=TYPE1,TYPE2,...", Array,
                  "Target MIME types",
                  "(e.g.: text/html,application/xhtml+xml)") do |mime_types|
          @mime_types = mime_types
        end
        parser.on("--author=AUTHOR",
                  "Author",
                  "(e.g.: 'Your Name')",
                  "(default: #{@author})") do |author|
          @author = author
        end
        parser.on("--email=EMAIL",
                  "Author E-mail",
                  "(e.g.: your@email.address)",
                  "(default: #{@email})") do |email|
          @email = email
        end
        parser.on("--license=LICENSE",
                  "License",
                  "(e.g.: MIT)",
                  "(default: #{@license})") do |license|
          @license = license
        end
        parser
      end

      def read_missing_parameters
        @name       ||= read_parameter("--name")
        @extensions ||= read_parameter("--extensions")
        @mime_types ||= read_parameter("--mime-types")
        @author     ||= read_parameter("--author")
        @email      ||= read_parameter("--email")
        @license    ||= read_parameter("--license")
      end

      def read_parameter(long_option_name)
        target_option = @parser.top.list.find do |option|
          option.long.include?(long_option_name)
        end
        prompt = target_option.desc.join(" ") + ": "
        print(prompt)
        target_option.conv.call($stdin.gets.chomp)
      end

      def gem_name
        "chupa-text-decomposer-#{@name}"
      end

      def generate
        generate_gemspec
        generate_gemfile
        generate_rakefile
        generate_license
        generate_decomposer
        generate_test
        generate_test_helper
        generate_test_runner
      end

      def generate_gemspec
        create_file("#{gem_name}.gemspec") do |file|
          file.puts(<<-GEMSPEC)
# -*- mode: ruby; coding: utf-8 -*-

Gem::Specification.new do |spec|
  spec.name = "#{gem_name}"
  spec.version = "1.0.0"
  spec.author = "#{@author}"
  spec.email = "#{@email}"
  spec.summary = "ChupaText decomposer for #{@mime_types.join(' ')}."
  spec.description = spec.summary
  spec.license = "#{@license}"
  spec.files = ["\#{spec.name}.gemspec"]
  spec.files += Dir.glob("{README*,LICENSE*,Rakefile,Gemfile}")
  spec.files += Dir.glob("lib/**/*.rb")
  spec.files += Dir.glob("test/fixture/**/*")
  spec.files += Dir.glob("test/**/*.rb")

  spec.add_runtime_dependency("chupa-text")

  spec.add_development_dependency("bundler")
  spec.add_development_dependency("rake")
  spec.add_development_dependency("test-unit")
end
          GEMSPEC
        end
      end

      def generate_gemfile
        create_file("Gemfile") do |file|
          file.puts(<<-Gemfile)
# -*- mode: ruby; coding: utf-8 -*-

source "https://rubygems.org/"

gemspec
          Gemfile
        end
      end

      def generate_rakefile
        create_file("Rakefile") do |file|
          file.puts(<<-RAKEFILE)
# -*- mode: ruby; coding: utf-8 -*-

require "bundler/gem_tasks"

task :default => :test

desc "Run tests"
task :test do
  ruby("test/run-test.rb")
end
          RAKEFILE
        end
      end

      def generate_license
        return unless @license == lgplv2_1_or_later_license
        base_dir = File.join(File.dirname(__FILE__), "..", "..", "..")
        lgpl2_1_license_file = File.join(base_dir, "LICENSE.txt")
        create_file("LICENSE.txt") do |file|
          file.puts(File.read(lgpl2_1_license_file))
        end
      end

      def generate_decomposer
        create_file("lib/chupa-text/decomposers/#{@name}.rb") do |file|
          file.puts(<<-RUBY)
module ChupaText
  module Decomposers
    class #{@name.capitalize} < Decomposer
      def target?(data)
        #{@extensions.inspect}.include?(data.extension) or
          #{@mime_types.inspect}.include?(data.mime_type)
      end

      def decompose(data)
        raise NotImplementedError, "\#{self.class}\#\#{__method__} isn't implemented yet."
        text = "IMPLEMENTED ME"
        text_data = TextData.new(text)
        yield(text_data)
      end
    end
  end
end
          RUBY
        end
      end

      def generate_test
        create_file("test/test-#{@name}.rb") do |file|
          file.puts(<<-RUBY)
class Test#{@name.capitalize} < Test::Unit::TestCase
  include Helper

  def setup
    @decomposer = ChupaText::Decomposers::#{@name.capitalize}.new({})
  end

  sub_test_case("decompose") do
    def decompose(input_body)
      data = ChupaText::Data.new
      data.mime_type = #{@mime_types.first.dump}
      data.body = input_body

      decomposed = []
      @decomposer.decompose(data) do |decomposed_data|
        decomposed << decomposed_data
      end
      decomposed
    end

    def test_body
      input_body = "TODO"
      expected_text = "TODO"
      assert_equal([expected_text],
                   decompose(input_body).collect(&:body))
    end
  end
end
          RUBY
        end
      end

      def generate_test_helper
        create_file("test/helper.rb") do |file|
          file.puts(<<-RUBY)
module Helper
  def fixture_path(*components)
    base_dir = File.expand_path(File.dirname(__FILE__))
    File.join(base_dir, "fixture", *components)
  end
end
          RUBY
        end
      end

      def generate_test_runner
        create_file("test/run-test.rb") do |file|
          file.puts(<<-RUBY)
#!/usr/bin/env ruby

require "bundler/setup"

require "test-unit"

require "chupa-text"
ChupaText::Decomposers.load

require_relative "helper"

exit(Test::Unit::AutoRunner.run(true))
          RUBY
        end
      end

      def create_file(path, &block)
        real_path = File.join(gem_name, path)
        directory = File.dirname(real_path)
        unless File.exist?(directory)
          puts("Creating directory: #{directory}")
          FileUtils.mkdir_p(directory)
        end
        puts("Creating file:      #{real_path}")
        File.open(real_path, "w", &block)
      end
    end
  end
end
