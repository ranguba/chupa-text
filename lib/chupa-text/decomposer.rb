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

require "chupa-text/decomposer-registory"

module ChupaText
  class Decomposer
    class << self
      def registory
        @@registory ||= DecomposerRegistory.new
      end

      def load
        $LOAD_PATH.each do |load_path|
          next unless File.directory?(load_path)
          Dir.chdir(load_path) do
            Dir.glob("chupa-text/plugin/decomposer/*.rb") do |plugin_path|
              require plugin_path.gsub(/\.rb\z/, "")
            end
          end
        end
      end
    end

    def target?(data)
      false
    end

    def decompose(data)
    end
  end
end
