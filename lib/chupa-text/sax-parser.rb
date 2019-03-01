# Copyright (C) 2019  Kouhei Sutou <kou@clear-code.com>
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

require "cgi/util"
require "rexml/parsers/sax2parser"
require "rexml/sax2listener"

begin
  require "nokogiri"
rescue LoadError
end

module ChupaText
  class SAXParser
    class ParseError < Error
    end

    class << self
      def backend
        case ENV["CHUPA_TEXT_SAX_PARSER_BACKEND"]
        when "rexml"
          :rexml
        else
          if Object.const_defined?(:Nokogiri)
            :nokogiri
          else
            :rexml
          end
        end
      end
    end

    def initialize(input, listener)
      @input = input
      @listener = listener
    end

    if backend == :nokogiri
      def parse
        document = Document.new(@listener)
        parser = Nokogiri::XML::SAX::Parser.new(document)
        parser.parse(@input)
      end

      class Document < Nokogiri::XML::SAX::Document
        def initialize(listener)
          @listener = listener
          @namespaces_stack = []
        end

        def start_element_namespace(name,
                                    attributes=[],
                                    prefix=nil,
                                    uri=nil,
                                    namespaces=[])
          namespaces.each do |namespace_prefix, namespace_uri|
            @listener.start_prefix_mapping(namespace_prefix, namespace_uri)
          end
          attributes_hash = {}
          attributes.each do |attribute|
            attribute_qname = build_qname(attribute.prefix, attribute.localname)
            attributes_hash[attribute_qname] = attribute.value
          end
          @namespaces_stack.push(namespaces)
          @listener.start_element(uri,
                                  name,
                                  build_qname(prefix, name),
                                  attributes_hash)
        end

        def end_element_namespace(name, prefix=nil, uri=nil)
          @listener.end_element(uri, name, build_qname(prefix, name))
          namespaces = @namespaces_stack.pop
          namespaces.each do |namespace_prefix, _|
            @listener.end_prefix_mapping(namespace_prefix)
          end
        end

        def characters(text)
          @listener.characters(text)
        end

        def cdata_block(content)
          @listener.cdata(content)
        end

        def error(detail)
          raise ParseError, detail
        end

        private
        def build_qname(prefix, local_name)
          if prefix
            "#{prefix}:#{local_name}"
          else
            local_name
          end
        end
      end
    else
      def parse
        source = @input
        if source.is_a?(Archive::Zip::Codec::Deflate::Decompress)
          source = source.read
        end
        parser = REXML::Parsers::SAX2Parser.new(source)
        parser.listen(Listener.new(@listener))
        begin
          parser.parse
        rescue REXML::ParseException => error
          message = "#{error.class}: #{error.message}"
          raise ParseError, message
        end
      end

      class Listener
        include REXML::SAX2Listener

        def initialize(listener)
          @listener = listener
        end

        def start_prefix_mapping(*args)
          @listener.start_prefix_mapping(*args)
        end

        def end_prefix_mapping(*args)
          @listener.end_prefix_mapping(*args)
        end

        def start_element(*args)
          @listener.start_element(*args)
        end

        def end_element(*args)
          @listener.end_element(*args)
        end

        def characters(text)
          @listener.characters(CGI.unescapeHTML(text))
        end

        def cdata(content)
          @listener.cdata(CGI.unescapeHTML(content))
        end
      end
    end
  end

  class SAXListener
    include REXML::SAX2Listener
  end
end
