# News

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
