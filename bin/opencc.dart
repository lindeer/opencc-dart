
import 'dart:convert' show utf8;
import 'dart:io' show Directory, File, exit, stdout;

import 'package:opencc/opencc.dart';
import 'package:path/path.dart' as p;

const _usage = """
opencc [-i] [-c config] <input1> [input2] ...
  config: s2t or t2s.
  input: string text or a existing local file.
""";

void main(List<String> argv) async {
  final it = argv.iterator;
  bool inplace = false;
  var config = 's2t';
  final inputList = <String>[];
  while (it.moveNext()) {
    final opt = it.current;
    switch (opt) {
      case '-i':
        inplace = true;
        break;
      case '-c':
        if (it.moveNext() && !it.current.startsWith('-')) {
          config = it.current;
        } else {
          print("Error option '$opt':\n$_usage");
          exit(-1);
        }
        break;
      case '-h':
      case '--help':
        print(_usage);
        break;
      default:
        inputList.add(opt);
        break;
    }
  }

  for (final input in inputList) {
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
      if (inplace) {
        final tmp = Directory.systemTemp.createTempSync();
        final f = File(p.join(tmp.path, p.basename(input)));
        await f.openWrite().addStream(ss);
        f.copySync(file.path);
        f.deleteSync();
      } else {
        await stdout.addStream(ss);
      }
    }
  }
}
