# -*- ruby -*-
#
# Copyright (C) 2013-2024  Sutou Kouhei <kou@clear-code.com>
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

base_dir = Pathname(__FILE__).dirname
lib_dir = base_dir + "lib"
$LOAD_PATH.unshift(lib_dir.to_s)

require "chupa-text/version"

clean_white_space = lambda do |entry|
  entry.gsub(/(\A\n+|\n+\z)/, '') + "\n"
end

Gem::Specification.new do |spec|
  spec.name = "chupa-text"
  spec.version = ChupaText::VERSION
  spec.homepage = "http://ranguba.org/#about-chupa-text"
  spec.authors = ["Sutou Kouhei"]
  spec.email = ["kou@clear-code.com"]
  readme = File.read("README.md", :encoding => "UTF-8")
  entries = readme.split(/^\#\#\s(.*)$/)
  description = clean_white_space.call(entries[entries.index("Description") + 1])
  spec.summary, spec.description, = description.split(/\n\n+/, 3)
  spec.license = "LGPL-2.1+"
  spec.files = ["#{spec.name}.gemspec"]
  spec.files += ["README.md", "LICENSE.txt", "Rakefile", "Gemfile"]
  spec.files += [".yardopts"]
  spec.files += Dir.glob("data/*.conf")
  spec.files += Dir.glob("lib/**/*.rb")
  spec.files += Dir.glob("doc/text/*")
  spec.files += Dir.glob("test/**/*")
  Dir.chdir("bin") do
    spec.executables = Dir.glob("*")
  end

  spec.add_runtime_dependency("archive-zip", ">= 0.12.0")
  spec.add_runtime_dependency("csv", ">= 3.0.4")
  spec.add_runtime_dependency("logger")
  spec.add_runtime_dependency("rexml")
end
