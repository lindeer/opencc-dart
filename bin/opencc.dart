
import 'dart:convert' show utf8;
import 'dart:io' show File, exit, stdout;

import 'package:opencc/opencc.dart';

const _usage = """
opencc <config> <input>
  config: s2t or t2s.
  input: string text or a existing local file.
""";

void main(List<String> argv) async {
  if (argv.length < 2) {
    print('Error params:\n$_usage');
    exit(-1);
  }
  final config = argv[0];
  final input = argv[1];
  final file = File(input);
  if (!file.existsSync()) {
    final zh = ZhConverter(config);
    final text = zh.convert(input);
    zh.dispose();
    stdout.writeln(text);
  } else {
    final ss = file.openRead()
        .transform(utf8.decoder)
        .transform(ZhTransformer(config))
        .transform(utf8.encoder);
    await stdout.addStream(ss);
  }
}
