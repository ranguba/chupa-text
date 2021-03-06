# Copyright (C) 2013-2019  Kouhei Sutou <kou@clear-code.com>
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
require "timeout"

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
    def extract(input, &block)
      extract_recursive(ensure_data(input), &block)
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
      candidates = []
      @decomposers.each do |decomposer|
        score = decomposer.target_score(data)
        next if score.nil?
        candidates << [score, decomposer]
      end
      return nil if candidates.empty?
      candidate = candidates.sort_by {|score, _| -score}.first
      candidate[1]
    end

    def extract_recursive(target, &block)
      debug do
        "#{log_tag}[extract][target] <#{target.uri}>:<#{target.mime_type}>"
      end
      decomposer = find_decomposer(target)
      if decomposer.nil?
        if target.text_plain?
          debug {"#{log_tag}[extract][text-plain]"}
          utf8_data = target.to_utf8_body_data
          yield(utf8_data)
          utf8_data.release unless target == utf8_data
        else
          debug {"#{log_tag}[extract][decomposer] not found"}
          if target.text?
            utf8_data = target.to_utf8_body_data
            yield(utf8_data)
            utf8_data.release unless target == utf8_data
          end
        end
      else
        debug {"#{log_tag}[extract][decomposer] #{decomposer.class}"}
        with_timeout(target) do
          decomposer.decompose(target) do |decomposed|
            begin
              debug do
                "#{log_tag}[extract][decomposed] " +
                  "#{decomposer.class}: " +
                  "<#{target.uri}>: " +
                  "<#{target.mime_type}> -> <#{decomposed.mime_type}>"
              end
              extract_recursive(decomposed, &block)
            ensure
              decomposed.release
            end
          end
        end
      end
    end

    def with_timeout(data, &block)
      timeout = TimeoutValue.new("#{log_tag}[timeout]", data.timeout).raw
      if timeout
        begin
          Timeout.timeout(timeout, &block)
        rescue Timeout::Error
          raise TimeoutError.new(data, timeout)
        end
      else
        yield
      end
    end

    def log_tag
      "[extractor]"
    end
  end
end
