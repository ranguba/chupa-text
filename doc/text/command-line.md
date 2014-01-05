# How to use ChupaText as command line tool

You can extract text and meta-data from an input by `chupa-text`
command. `chupa-text` prints extracted text and meta-data as JSON.

## Input

`chupa-text` command accept a local file path or a URI.

Here is a local file path example:

```
% chupa-text hello.txt.gz
```

Here is an URI example:

```
% chupa-text https://github.com/ranguba/chupa-text/raw/master/test/fixture/gzip/hello.txt.gz
```

## Output

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

## Command line options

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

## Configuration

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

`mime_types["<extension>"] = "<MIME type>"`

It specifies a map to a MIME type from path extension.

Here is an example that maps `"html"` to `"text/html"`:

```
mime_types["html"] = "text/html"
```

Th default configuration file registers popular MIME types.
