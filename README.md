# README

## Name

ChupaText

## Description

ChupaText is an extensible text extractor. You can plug your custom
text extractor in ChupaText. You can write your plugin by Ruby.

## Overview

ChupaText applies registered decomposers to input data
recursively. Finally, the input data is decomposed to text data.

Here is an ASCII art to describe process flow:

```
input data
     |
    \|/
|decomposer|
     |
    \|/
other data
     |
    \|/
|decomposer|
     |
    \|/
...
     |
    \|/
|decomposer|
     |
    \|/
text data
```

Decomposer is a module that decomposes input data to other data. The
decomposed data may not be text data. If the decomposed data is not
text data, ChupaText applies a decomposer again. Finally, the
decomposed data will be text data.

Decomposer module is a plugin. You can add supported data types by
installing decomposer modules. Or you can create your custom
decomposer. Decomposer is a simple Ruby object. So it is easy to
write. It is described later.

## Install

Install `chupa-text` gem:

```
% gem install chupa-text
```

Now, you can use `chupa-text` command:

```
% chupa-text --version
chupa-text 1.0.0
```

## How to use

You can use ChupaText as command line tool or Ruby library.

### How to use as command line tool

You can extract text and meta-data from an input by `chupa-text`
command. `chupa-text` prints extracted text and meta-data as JSON.

#### Input

`chupa-text` command accept a local file path or a URI.

Here is a local file path example:

```
% chupa-text hello.txt.gz
```

Here is an URI example:

```
% chupa-text https://github.com/ranguba/chupa-text/raw/master/test/fixture/gzip/hello.txt.gz
```

#### Output

`chupa-text` command prints the extracted result as JSON:

```
% chupa-text hello.txt.gz
{
  "mime-type": "application/x-gzip",
  "uri": "hello.txt.gz",
  "size": 36,
  "texts": [
    {
      "mime-type": "text/plain",
      "uri": "hello.txt",
      "size": 6,
      "body": "Hello\n"
    }
  ]
}
```

JSON uses the following data structure:

```txt
{
  "mime-type":        "<MIME type of the input>",
  "uri":              "<URI or path of the input>",
  "size":             <Byte size of the input data>,
  "other-meta-data1": <Other meta-data value1>,
  "other-meta-data2": <Other meta-data value2>,
  "...":              <...>,
  "texts": [
    {
      "mime-type":        "<MIME type of the extracted data1>",
      "uri":              "<URI or path of the extracted data1>",
      "size":             "<Byte size of the text of the extracted data1>",
      "body":             "<The text of the extracted data1>",
      "other-meta-data1": <Other meta-data value1 of the extracted data1>,
      "other-meta-data2": <Other meta-data value2 of the extracted data1>,
      "...":              <...>
    },
    {
      <The information of the extracted data2>
    },
    {
      <The information of the extracted data3>
    },
    <...>
  ]
}
```

You can find extracted texts in `texts[0].body`, `texts[1].body` and
so on. You may extract one or more texts from one input because
ChupaText supports archive file such as `tar`.

#### Command line options

You can custom `chupa-text` command behavior. Here are command line
options:

`--configuration=FILE`

It reads configuration from `FILE`. See the next section for
configuration file details.

ChupaText provides the default configuration file. It has suitable
configurations. Normally, you don't need to use your custom
configuration file.

`--help`

It shows available command line options and exits.

#### Configuration

ChupaText configuration file is a Ruby script but it is easy to read
and write ChupaText configuration file for users who don't know about
Ruby.

The basic syntax is the following:

```
category.name = value
```

Here is an example that sets `["tar", "gzip"]` as `value` to `names`
name variable in `decomposer` category:

```
decomposer.names = ["tar", "gzip"]
```

Here are configuration parameters:

`decomposer.names = ["<decomposer name1>", "<decomposer name2>, "..."]`

It specifies an array of decomposer name to be used in `chupa-text`
command. You can use glob pattern for decomposer name such as
`"*zip"`. `"*zip"` matches `"zip"`, `"gzip"` and so on.

The default is `["*"]`. It means that all installed decomposers are
used.

`mime_type["<extension>"] = "<MIME type>"`

It specifies a map to a MIME type from path extension.

Here is an example that maps `"html"` to `"text/html"`:

```
mime_type["html"] = "text/html"
```

Th default configuration file registers popular MIME types.

### How to use as Ruby library

You can use ChupaText as a Ruby library. If you want to extract text
data from many input data, `chupa-text` command may be
inefficient. You need to execute `chupa-text` command to process one
input file. You need to execute `chupa-text` command N times to
process N input files. It means that you need to initializes ChupaText
N times. It may be inefficient.

You can reduce initializations of ChupaText by using ChupaText as a
Ruby library.

Here is a simple usage:

```
require "chupa-text"
gem "chupa-text-decomposer-html"

ChupaText::Decomposers.load

extractor = ChupaText::Extractor.new
extractor.apply_configuration(ChupaText::Configuration.default)

extractor.extract("http://ranguba.org/") do |text_data|
  puts(text_data.body)
end
extractor.extract("http://ranguba.org/ja/") do |text_data|
  puts(text_data.body)
end
```

It is better that you use Bundler to manager decomposer plugins:

```
# Gemfile
source "https://rubygems.org"

gem "chupa-text-decomposer-html"
gem "chupa-text-decomposer-XXX"
# ...
```

Here is a usage that uses the Gemfile:

```
require "bundler/setup"

ChupaText::Decomposers.load

extractor = ChupaText::Extractor.new
extractor.apply_configuration(ChupaText::Configuration.default)

extractor.extract("http://ranguba.org/") do |text_data|
  puts(text_data.body)
end
extractor.extract("http://ranguba.org/ja/") do |text_data|
  puts(text_data.body)
end
```

Use {ChupaText::Data#[]} to get meta-data from extracted text
data. For example, you can get title from input HTML:

```
extractor.extract("http://ranguba.org/") do |text_data|
  puts(text_data["title"])
end
```

It is depended on decomposer that what meta-data can be got. See
decomposer's documentation to know about it.

## Author

  * Kouhei Sutou `<kou@clear-code.com>`

## License

LGPL 2.1 or later.

(Kouhei Sutou has a right to change the license including contributed
patches.)
