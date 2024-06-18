import 'dart:async' show StreamTransformerBase;
import 'dart:io' show Platform;

import 'src/ffi.dart' show CharArray;
import 'src/lib_opencc.dart' as lib;

final class ZhTransformer extends StreamTransformerBase<String, String> {
  final String _config;

  const ZhTransformer(this._config);

  @override
  Stream<String> bind(Stream<String> stream) async* {
    final zh = ZhConverter(_config);
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
          yield zh.convert(line);
        }
      }
    }
    zh.dispose();
  }
}

final class ZhConverter {
  final lib.opencc_t _native;
  final CharArray _str;
  final CharArray _buf;

  const ZhConverter._(this._native, this._str, this._buf);

  factory ZhConverter(String config) {
    final str = CharArray.from('$config.json');
    final buf = CharArray(size: 1024);
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

  void dispose() {
    lib.opencc_close(_native);
    _buf.dispose();
    _str.dispose();
  }
}
