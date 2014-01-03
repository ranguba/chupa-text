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
  class Extractor
    def initialize
      @decomposers = []
    end

    # Sets the extractor up by the configuration. It adds decomposers
    # enabled in the configuration.
    #
    # @param [Configuration] configuration The configuration to be
    #   applied.
    #
    # @return [void]
    def apply_configuration(configuration)
      decomposers = Decomposers.create(Decomposer.registry,
                                       configuration.decomposer)
      decomposers.each do |decomposer|
        add_decomposer(decomposer)
      end
    end

    def add_decomposer(decomposer)
      @decomposers << decomposer
    end

    def extract(data)
      targets = [data]
      until targets.empty?
        target = targets.pop
        decomposer = find_decomposer(target)
        if decomposer.nil?
          yield(target) if target.text?
          next
        end
        decomposer.decompose(target) do |decomposed|
          targets.push(decomposed)
        end
      end
    end

    private
    def find_decomposer(data)
      @decomposers.find do |decomposer|
        decomposer.target?(data)
      end
    end
  end
end
