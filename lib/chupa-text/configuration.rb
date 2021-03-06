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
  class Configuration
    class << self
      def default
        @default ||= load_default
      end

      def load_default
        configuration = new
        loader = ConfigurationLoader.new(configuration)
        loader.load("chupa-text.conf")
        configuration
      end
    end

    attr_reader :decomposer
    attr_accessor :mime_type_registry
    def initialize
      @decomposer = DecomposerConfiguration.new
      @mime_type_registry = MIMEType.registry
    end

    class DecomposerConfiguration
      attr_accessor :names
      attr_accessor :options
      def initialize
        @names = ["*"]
        @options = {}
      end
    end
  end
end
