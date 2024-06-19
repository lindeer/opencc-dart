import 'dart:convert' show utf8;
import 'dart:io' show stdout;

import 'package:opencc/opencc.dart';

void main(List<String> argv) async {
  print(_convert('s2t', '简体转繁体'));
  final ss = _transform('t2s', Stream.value('繁體轉簡體'));
  stdout.addStream(ss.transform(utf8.encoder));
}

String _convert(String config, String text) {
  final zh = ZhConverter(config);
  return zh.convert(text);
}

Stream<String> _transform(String config, Stream<String> ss) {
  final zh = ZhTransformer(config);
  return ss.transform(zh);
}
