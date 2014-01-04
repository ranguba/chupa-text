# How to create a decomposer

You can extend ChupaText by Ruby. You can add supported input type by
writing a decomposer module.

## Overview

Decomposer is a Ruby class. It needs the following two API:

  * `target?`
  * `decompose`

Both of them accept only one argument `data`. `data` is an input
data.

First, ChupaText calls `target?` method of your decomposer. If your
decomposer can decompose the input data, your `target?` method should
return `true`.

If your decomposer's `target?` method returns `true`, ChupaText calls
`decomposer` method of your decomposer. Your decomposer needs to
decomposer the input data and `yield` extracted text data or other
format data that will be decomposed by other decomposers. Your
decomposer can `yield` multiple times.

If your decomposer decomposes an archive file such as tar and zip
archives, your `decompose` method will `yield` other format data. If
your decomposer extracts text and meta-data from an input such as
HTML, your `decompose` method will `yield` text data.

## Example

Let's create a simple XML decomposer as an example. It extracts text
data from input XML.

For example, here is an input XML:

```xml
<root>
  Hello <em>&amp;</em> World!
</root>
```

The XML decomposer extracts the following text:

```text
Hello & World!
```

ChupaText provides `chupa-text-genearte-decomposer` command. It
generates skeleton code for a new decomposer. Let's use it.

`chupa-text-genearte-decomposer` accepts required information by
command line options or reading from standard input. You can confirm
the required information by `--help` option:

```text
% chupa-text-generate-decomposer --help
Usage: chupa-text-generate-decomposer [options]
        --name=NAME                  Decomposer name
                                     (e.g.: html)
        --extensions=EXTENSION1,EXTENSION2,...
                                     Target file extensions
                                     (e.g.: htm,html,xhtml)
        --mime-types=TYPE1,TYPE2,... Target MIME types
                                     (e.g.: text/html,application/xhtml+xml)
        --author=AUTHOR              Author
                                     (e.g.: 'Your Name')
                                     (default: Kouhei Sutou)
        --email=EMAIL                Author E-mail
                                     (e.g.: your@email.address)
                                     (default: kou@clear-code.com)
        --license=LICENSE            License
                                     (e.g.: MIT)
                                     (default: LGPLv2.1 or later)
```

Some pieces of information have the default values. In the above case,
`--author`, `--email` and `-license` have the default values.

XML decomposer uses the following information:

  * `--name`: `xml`
  * `--extensions`: `xml`
  * `--mime-types`: `text/xml`

Run with the above information:

```text
% chupa-text-generate-decomposer --name xml --extensions xml --mime-types text/xml
Creating directory: chupa-text-decomposer-xml
Creating file:      chupa-text-decomposer-xml/chupa-text-decomposer-xml.gemspec
Creating file:      chupa-text-decomposer-xml/Gemfile
Creating file:      chupa-text-decomposer-xml/Rakefile
Creating file:      chupa-text-decomposer-xml/LICENSE.txt
Creating directory: chupa-text-decomposer-xml/lib/chupa-text/decomposers
Creating file:      chupa-text-decomposer-xml/lib/chupa-text/decomposers/xml.rb
Creating directory: chupa-text-decomposer-xml/test
Creating file:      chupa-text-decomposer-xml/test/test-xml.rb
Creating file:      chupa-text-decomposer-xml/test/helper.rb
Creating file:      chupa-text-decomposer-xml/test/run-test.rb
```

`chupa-text-generate-decomposer` generates a directory that is named
as `chupa-text-decomposer-#{name}/`.

Look `lib/chupa-text/decomposers/xml.rb`:

```
module ChupaText
  module Decomposers
    class Xml < Decomposer
      def target?(data)
        ["xml"].include?(data.extension) or
          ["text/xml"].include?(data.mime_type)
      end

      def decompose(data)
        raise NotImplementedError, "#{self.class}##{__method__} isn't implemented yet."
        text = "IMPLEMENTED ME"
        text_data = TextData.new(text)
        yield(text_data)
      end
    end
  end
end
```

The generated code implements `target?` method but doesn't implemented
`decompose` method completely. Let's implement `decompose` method:

```
require "cgi"

# ...
      def decompose(data)
        text = CGI.unescapeHTML(untag(data.body).strip)
        text_data = TextData.new(text)
        yield(text_data)
      end

      private
      def untag(xml)
        xml.gsub(/<.+?>/m, "")
      end
# ...
```

`chupa-text-generate-decomposer` also generates a test. Run the test:

```
% bundle install
% rake
/usr/bin/ruby2.0 test/run-test.rb
Loaded suite .
Started
F
===============================================================================
Failure:
test_body(decompose)
/tmp/chupa-text-decomposer-xml/test/test-xml.rb:24:in `test_body'
     21:     def test_body
     22:       input_body = "TODO (input)"
     23:       expected_text = "TODO (extracted)"
  => 24:       assert_equal([expected_text],
     25:                    decompose(input_body).collect(&:body))
     26:     end
     27:   end
<["TODO (extracted)"]> expected but was
<["TODO (input)"]>

diff:
? ["TODO (ex  tracted)"]
?         inpu          
===============================================================================


Finished in 0.013355116 seconds.

1 tests, 1 assertions, 1 failures, 0 errors, 0 pendings, 0 omissions, 0 notifications
0% passed

74.88 tests/s, 74.88 assertions/s
rake aborted!
Command failed with status (1): [/usr/bin/ruby2.0 test/run-test.rb...]
/tmp/chupa-text-decomposer-xml/Rakefile:9:in `block in <top (required)>'
```

The generated test fails because the test has place holders. Look the
generated test:

```
class TestXml < Test::Unit::TestCase
  include Helper

  def setup
    @decomposer = ChupaText::Decomposers::Xml.new({})
  end

  sub_test_case("decompose") do
    def decompose(input_body)
      data = ChupaText::Data.new
      data.mime_type = "text/xml"
      data.body = input_body

      decomposed = []
      @decomposer.decompose(data) do |decomposed_data|
        decomposed << decomposed_data
      end
      decomposed
    end

    def test_body
      input_body = "TODO (input)"
      expected_text = "TODO (extracted)"
      assert_equal([expected_text],
                   decompose(input_body).collect(&:body))
    end
  end
end
```

`test_body` has TODO codes as place holder:

```
# ...
    def test_body
      input_body = "TODO (input)"
      expected_text = "TODO (extracted)"
      assert_equal([expected_text],
                   decompose(input_body).collect(&:body))
    end
# ...
```

Fill the TODO by test XML and expected result:

```
# ...
    def test_body
      input_body = <<-XML
<root>
  Hello <em>&amp;</em> World!
</root>
      XML
      expected_text = "Hello & World!"
      assert_equal([expected_text],
                   decompose(input_body).collect(&:body))
    end
# ...
```

Run test again:

```
% rake
/usr/bin/ruby2.0 test/run-test.rb
Loaded suite .
Started
.

Finished in 0.000915172 seconds.

1 tests, 1 assertions, 0 failures, 0 errors, 0 pendings, 0 omissions, 0 notifications
100% passed

1092.69 tests/s, 1092.69 assertions/s
```

The test is passed!

You can release the generator by the following command. It requires an
account on https://rubygems.org/.

```
% rake release
```

Can you understand how to create a new decomposer?

## API reference

### `data`

Both of `target?` and `decompose` receives an argument `data`. It is a
{ChupaText::Data} instance or an instance of its sub class. You need
to see the API reference manual just for {ChupaText::Data}. You don't
use sub class specific API. It is not portable.

### `target?`

`target?` should return `true` or `false`. The decomposer should
return `true` if the decomposer can decompose received `data`, `false`
otherwise.

### `decompose`

`decompose` decomposes input `data` and `yield` extracted text data or
decomposed other type data. `decompose` can `yield` zero or more
times.

Here is a template code to `yield` extracted text data:

```
def decompose(data)
  text = extract_text(data)
  text_data = ChupaText::TextData.new(text)
  # text_data["meta-data1"] = meta_data_value1
  # text_data["meta-data2"] = meta_data_value2
  # ...
  yield(text_data)
end
```

See
[lib/chupa-text/decomposers/csv.rb](https://github.com/ranguba/chupa-text/blob/master/lib/chupa-text/decomposers/csv.rb)
as an example of extracting text data.

Here is a template code to `yield` other type data:

```
def decompose(data)
  entries = decompose_archive(data)
  entries.each do |entry|
    path = entry.path
    if entry.respond_to?(:read)
      # The input must have "read" method.
      input = entry
    else
      # If the entry doesn't have "read" method, wrap String data
      # by StringIO.
      input = StringIO.new(entry.data)
    end
    decomposed_data = ChupaText::VirtualFileData.new(path, input)
    decomposed_data.source = data
    yield(decomposed_data)
  end
end
```

See
[lib/chupa-text/decomposers/tar.rb](https://github.com/ranguba/chupa-text/blob/master/lib/chupa-text/decomposers/tar.rb)
as an example of decomposing to other type data.
