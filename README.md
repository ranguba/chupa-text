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
create. It is described later.

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

You can use ChupaText as command line tool or Ruby library. See the
following documentations for details:

  * [doc/text/command-line.md](http://rubydoc.info/gems/chupa-text/file/doc/text/command-line.md)
    describes how to use ChupaText as command line tool.
  * [doc/text/library.md](http://rubydoc.info/gems/chupa-text/file/doc/text/library.md)
    describes how to use ChupaText as a Ruby library.

## How to create a decomposer

See
[doc/text/decomposer.md](http://rubydoc.info/gems/chupa-text/file/doc/text/decomposer.md)
how to write a decomposer.

## Author

  * Kouhei Sutou `<kou@clear-code.com>`

## License

LGPL 2.1 or later.

(Kouhei Sutou has a right to change the license including contributed
patches.)
