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
    def initialize(configuration=nil)
      @configuration = configuration || Configuration.new
    end

    def load(path)
      File.open(path) do |file|
        instance_eval(file.read, path, 1)
      end
    end

    def decomposer
      DecomposerConfigurationLoader.new(@configuration.decomposer)
    end

    class DecomposerConfigurationLoader
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

        case arguments.size
        when 0
          self[name.to_s]
        when 1
          value = arguments.first
          self[name.to_s] = value
        else
          super
        end
      end
    end
  end
end
