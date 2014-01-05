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
  module Decomposers
    class << self
      def enable_all_gems
        decomposer_specs = Gem::Specification.find_all do |spec|
          spec.name.start_with?("chupa-text-decomposer-")
        end
        grouped_decomposer_specs = decomposer_specs.group_by(&:name)
        latest_decomposer_specs = []
        grouped_decomposer_specs.each do |name, specs|
          latest_decomposer_specs << specs.sort_by(&:version).last
        end
        latest_decomposer_specs.each do |spec|
          gem(spec.name, spec.version)
        end
      end

      def load
        paths = []
        $LOAD_PATH.each do |load_path|
          next unless File.directory?(load_path)
          Dir.chdir(load_path) do
            Dir.glob("chupa-text/decomposers/*.rb") do |decomposer_path|
              paths << decomposer_path.gsub(/\.rb\z/, "")
            end
          end
        end
        paths.each do |path|
          require path
        end
      end

      def create(registry, configuration)
        enabled_names = resolve_names(registry, configuration.names)
        enabled_names.collect do |enabled_name|
          decomposer_class = registry.find(enabled_name)
          options = configuration.options[name] || {}
          decomposer_class.new(options)
        end
      end

      private
      def resolve_names(registry, enabled_names)
        resolved_names = []
        flag = 0
        flag |= File::FNM_EXTGLOB if File.const_defined?(:FNM_EXTGLOB)
        enabled_names.each do |enabled_name|
          registry.each do |name,|
            next unless File.fnmatch(enabled_name, name, flag)
            resolved_names << name
          end
        end
        resolved_names
      end
    end
  end
end
