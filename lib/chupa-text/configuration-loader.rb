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

require "chupa-text/configuration"

module ChupaText
  class ConfigurationLoader
    attr_reader :decomposer
    attr_reader :content_type
    def initialize(configuration)
      @configuration = configuration
      @decomposer = DecomposerLoader.new(@configuration.decomposer)
      @content_type = ContentTypeLoader.new(@configuration.content_type_registry)
      @load_paths = []
      data_dir = File.join(File.dirname(__FILE__), "..", "..", "data")
      @load_paths << File.expand_path(data_dir)
    end

    def load(path)
      path = resolve_path(path)
      File.open(path) do |file|
        instance_eval(file.read, path, 1)
      end
    end

    private
    def resolve_path(path)
      return path if File.exist?(path)
      return path if Pathname(path).absolute?
      @load_paths.each do |load_path|
        resolved_path = File.join(load_path, path)
        return resolved_path if File.exist?(resolved_path)
      end
      path
    end

    class DecomposerLoader
      def initialize(configuration)
        @configuration = configuration
      end

      def names
        @configuration.names
      end

      def names=(names)
        @configuration.names = names
      end

      def [](name)
        @configuration.options[name]
      end

      def []=(name, options)
        @configuration.options[name] = options
      end

      def method_missing(name, *arguments)
        return super if block_given?

        if name.to_s.end_with?("=") and arguments.size == 1
          value = arguments.first
          self[name.to_s.gsub(/=\z/, "")] = value
        elsif arguments.empty?
          self[name.to_s]
        else
          super
        end
      end
    end

    class ContentTypeLoader
      def initialize(registry)
        @registry = registry
      end

      def []=(extension, content_type)
        @registry.register(extension, content_type)
      end
    end
  end
end
