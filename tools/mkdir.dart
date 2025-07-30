import 'dart:io';

import 'package:path/path.dart' as p;

void main(List<String> argv) {
  for (final arg in argv) {
    final path = Uri.directory(p.joinAll(arg.split('/')));
    final dir = Directory.fromUri(path);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
  }
}
