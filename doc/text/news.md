# News

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
