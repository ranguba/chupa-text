# Hot to use ChupaText as Ruby library

You can use ChupaText as Ruby library. If you want to extract text
data from many input data, `chupa-text` command may be
inefficient. You need to execute `chupa-text` command to process one
input file. You need to execute `chupa-text` command N times to
process N input files. It means that you need to initializes ChupaText
N times. It may be inefficient.

You can reduce initializations of ChupaText by using ChupaText as Ruby
library.

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

