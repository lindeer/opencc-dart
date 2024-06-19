import 'dart:async' show StreamTransformerBase;
import 'dart:io' show Platform;

import 'src/ffi.dart' show CharArray;
import 'src/lib_opencc.dart' as lib;

/// A class for streaming text
final class ZhTransformer extends StreamTransformerBase<String, String> {
  final ZhConverter _converter;

  const ZhTransformer._(this._converter);

  /// [config] would not have to add `.json` suffix.
  ZhTransformer(String config) : this._(ZhConverter(config, large: true));

  @override
  Stream<String> bind(Stream<String> stream) async* {
    final eol = Platform.lineTerminator;
    await for (final text in stream) {
      final lines = text.split(eol);
      var pos = 0;
      for (final line in lines) {
        if (pos++ != 0) {
          yield eol;
        }
        if (line.trim().isEmpty) {
          yield line;
        } else {
          yield _converter.convert(line);
        }
      }
    }
  }

  /// `dispose` would have to be called after using, as we need release native
  /// resources.
  void dispose() {
    _converter.dispose();
  }
}

/// A class for text segments.
final class ZhConverter {
  final lib.opencc_t _native;
  final CharArray _str;
  final CharArray _buf;

  const ZhConverter._(this._native, this._str, this._buf);

  /// [config] would not have to add `.json` suffix.
  /// [large] indicate whether to use large memory chunk.
  factory ZhConverter(String config, {bool? large}) {
    final size = large == true ? 4096 : 1024;
    final str = CharArray(size: size);
    final buf = CharArray(size: size);
    str.pavedBy('$config.json');
    final native = lib.opencc_open(str.pointer);
    if (native.address < 0) {
      final err = CharArray.toDartString(lib.opencc_error());
      str.dispose();
      buf.dispose();
      throw Exception("Failed to open opencc with config '$config'!\n"
          "  Error: '$err'");
    }
    return ZhConverter._(native, str, buf);
  }

  /// Convert the given [text] to target text as configured.
  String convert(String text) {
    _str.pavedBy(text);
    _buf.resize(_str.length + 1);
    final len = lib.opencc_convert_utf8_to_buffer(
      _native,
      _str.pointer,
      _str.length,
      _buf.pointer,
    );
    if (len < 0) {
      dispose();
      throw Exception("Error converting: '$text'");
    }
    return CharArray.toDartString(_buf.pointer, len);
  }

  /// Release native resources.
  /// An error would occur if called twice.
  void dispose() {
    lib.opencc_close(_native);
    _buf.dispose();
    _str.dispose();
  }
}
