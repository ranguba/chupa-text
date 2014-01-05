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

require "pathname"
require "uri"

module ChupaText
  class Extractor
    include Loggable

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

    # Extracts texts from input. Each extracted text is passes to the
    # given block.
    #
    # @param [Data, String] input The input to be extracted texts.
    #   If `input` is `String`, it is treated as the local file path or URI
    #   of input data.
    #
    # @yield [text_data] Gives extracted text data to the block.
    #   The block may be called zero or more times.
    # @yieldparam [Data] text_data The extracted text data.
    #   You can get text data by `text_data.body`.
    #
    # @return [void]
    def extract(input)
      targets = [ensure_data(input)]
      until targets.empty?
        target = targets.pop
        debug do
          "#{log_tag}[extract][target] <#{target.path}>:<#{target.mime_type}>"
        end
        if target.text_plain?
          yield(target)
          next
        end
        decomposer = find_decomposer(target)
        if decomposer.nil?
          debug {"#{log_tag}[extract][decomposer] not found"}
          yield(target) if target.text?
          next
        end
        debug {"#{log_tag}[extract][decomposer] #{decomposer.class}"}
        decomposer.decompose(target) do |decomposed|
          debug do
            "#{log_tag}[extract][decomposed] " +
              "#{decomposer.class}: " +
              "<#{target.path}>:<#{target.mime_type}> -> " +
              "<#{decomposed.mime_type}>"
          end
          targets.push(decomposed)
        end
      end
    end

    private
    def ensure_data(input)
      if input.is_a?(Data)
        input
      else
        InputData.new(input)
      end
    end

    def find_decomposer(data)
      @decomposers.find do |decomposer|
        decomposer.target?(data)
      end
    end

    def log_tag
      "[extractor]"
    end
  end
end
