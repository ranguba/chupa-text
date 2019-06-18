# News

## 1.3.1: 2019-06-18

### Fixes

  * `http-server`: Added support for `need_screenshot` parameter.

## 1.3.0: 2019-06-14

### Fixes

  * Added support for timeout as string again.

## 1.2.9: 2019-06-13

### Improvements

  * `http-server`: Logged more information on error.

## 1.2.8: 2019-06-13

### Improvements

  * `http-server`: Reduced timeout in server.

## 1.2.7: 2019-06-13

### Improvements

  * Added support for timeout.

## 1.2.6: 2019-06-10

### Improvements

  * `http-server`: Added support for `Expect: 100-continue`.

  * Removed temporary files immediately.

## 1.2.5: 2019-05-20

### Improvements

  * `http-server`: Added support for changing the default URL at run-time.

## 1.2.4: 2019-03-29

### Fixes

  * `http-server`: Fixed score.

## 1.2.3: 2019-03-28

### Fixes

  * Added support for Ruby 2.5 or earlier again.

## 1.2.2: 2019-03-28

### Improvements

  * Added `http-server` decomposer.

  * `ChupaText::Data#max_body_size`: Added.

  * `ChupaText::Data#max_body_size=`: Added.

  * `ChupaText::Data#timeout`: Added.

  * `ChupaText::Data#timeout=`: Added.

  * `ChupaText::Data#limit_cpu`: Added.

  * `ChupaText::Data#limit_cpu=`: Added.

  * `ChupaText::Data#limit_ax`: Added.

  * `ChupaText::Data#limit_ax=`: Added.

  * `ChupaText::ExternalCommand`: Added support for soft timeout and limits.

  * `ChupaText::Extractor`: Stopped receiving the max body size as an
    option. Use `ChupaText::Data#max_body_size=` instead.

### Fixes

  * Fixed decomposer choose logic.

## 1.2.1: 2019-03-04

### Improvements

  * `ChupaText::ExternalCommand`:

    * Added more logs.

    * Added support for ensuring killing external command.

    * Added default value API.

  * `ChupaText::VirtualFileContent`:

    * Added support for inlining small data.

## 1.2.0: 2019-03-03

### Improvements

  * Added support timeout for external command execution by
    `CHUPA_TEXT_EXTERNAL_COMMAND_TIMEOUT` environment variable.

## 1.1.9: 2019-03-03

### Improvements

  * Added `ChupaText::CaptureLogger`.

## 1.1.8: 2019-03-03

### Improvements

  * `gzip`: Added error checks.

  * `xml`:

     * Added error checks.

     * Added support for Nokogiri as an alternative backend.

  * Reduced memory usage.

  * Added support for body size limitation.

  * `opendocument`: Added error checks.

  * `office-open-xml`: Added error checks.

## 1.1.7: 2019-03-01

### Improvements

  * Reduced memory usage.

  * Reduced IO.

## 1.1.6: 2019-03-01

### Improvements

  * `zip`:

    * Added support for multibyte path.

    * Added error check.

  * `tar`:

    * Added support for multibyte path.

    * Reduced memory usage.

  * Changed to the extracted text encoding to UTF-8.

  * Added support BOM detection.

  * Improved binary data detection.

  * `office-open-xml-workbook`:

    * Added support for not shared string cell values.

    * Changed to emit data per sheet.

  * `office-open-xml-presentation`:

    * Changed to emit data per slide.

  * `csv`:

    * Added error check.

  * `opendocument-spreadsheet`:

    * Added support for concatenated cell.

    * Added support for shapes.

## 1.1.5: 2019-02-28

### Improvements

  * Added support for Nokogiri as an alternative SAX parser.

## 1.1.4: 2019-02-26

### Improvements

  * Added support for decomposer selection by score.

  * Added support for Office Open XML.

  * Added support for OpenDocument.

  * `chupa-text`: Added `--mime-boundary` option.

## 1.1.3: 2018-07-18

### Improvements

  * Added support for long base name file.

## 1.1.2: 2018-06-18

### Improvements

  * Added support for Ruby 2.6.

## 1.1.1: 2017-12-13

### Improvements

  * Added MIME formatter.
    [GitHub#4][Patch by okkez]

### Thanks

  * okkez

## 1.1.0: 2017-07-12

### Improvements

  * Supported external command limitation by the following environment
    variables:

    * `CHUPA_TEXT_EXTERNAL_COMMAND_LIMIT_CPU`

    * `CHUPA_TEXT_EXTERNAL_COMMAND_LIMIT_AS`

  * Handled more download errors.

  * Improved extension detection.

## 1.0.9: 2017-07-11

### Improvements

  * `ChupaText::TextData`: Changed extension to ".txt".

  * `chupa-text`: Added `--uri` option.

  * `chupa-text`: Added `--mime-type` option.

  * `ChupaText::DownloadError`: Added.

  * Supported zip.

  * `ChupaText::ExternalCommand#path`: Added.

## 1.0.8: 2017-07-10

### Improvements

  * `ChupaText::VirtualContent`: Accepted `Pathname`.

### Fixes

  * `ChupaText::VirtualFileData#path`: Fixed a bug that it doesn't
    return real path.

## 1.0.7: 2017-07-06

### Improvements

  * Supported screenshot.

  * `chupa-text`: Added new options:

    * `--need-screenshot`

    * `--expected-screenshot-size=WIDTHxHEIGHT`

### Fixes

  * CSV decomposer: Fixed a infinite loop bug.

## 1.0.6: 2017-07-05

### Improvements

  * Supported non ASCII characters in file name.

## 1.0.5: 2017-05-02

### Improvements

  * Added `message/rfc822` MIME type association with `.eml` and
    `.mew` into the default MIME type list.

  * Searched decomposer even if MIME type is `text/plain`.

  * `ChupaText::Data#initialize`: Accepted source data.

  * `ChupaText::UnknownEncodingError`: Added.

  * Added plain text formatter.

## 1.0.4: 2014-02-17

  * Removed a needless optimization.

## 1.0.3: 2014-02-17

  * Added `ChupaText::EncryptedError`.
  * Added `ChupaText::InvalidDataError`.
  * Added `ChupaText::Attributes`.
  * `ChupaText::Data#attributes` returns `ChupaText::Attributes` instead
    of `Hash`.

## 1.0.2: 2014-02-15

  * Added `ChupaText::SizeParser`.
  * Added `ChupaText::DefaultLogger`.
  * chupa-text: Added `--log-output` option.
  * chupa-text: Added `--log-level` option.
  * Added `ChupaText::ExternalCommand`.
  * Added MIME types for office files.

## 1.0.1: 2014-01-05

  * chupa-text: Supported loading decomposers installed by RubyGems.
  * chupa-text: Added `--disable-gems` option that disable loading
    decomposers installed by RubyGems.
  * chupa-text: Added `-I` option to use decomposers that are not
    installed by RubyGems.
  * Added {ChupaText::Data#text_plain?}.
  * configuration: Changed `mime_types` from `mime_type` because they
    processes about a set of MIME types.
  * configuration: Added PDF to the default MIME type mappings.

## 1.0.0: 2014-01-05

The first release!!!
