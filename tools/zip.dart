import 'dart:io' show Directory, File;

import 'package:path/path.dart' as p;
import 'package:glob/glob.dart' show Glob;
import 'package:glob/list_local_fs.dart';
import 'package:zip2/zip2.dart' show ZipArchive, ZipFileEntry, ZipEntryItorExt;

Iterable<String> _expand(Iterable<String> files) sync* {
  final entities = files.expand((f) => Glob(f).listSync());
  for (final f in entities) {
    final paths = f is Directory ? _listRecursive(f as Directory) : [f.path];
    yield* paths.map((f) => p.normalize(p.relative(f, from: '.')));
  }
}

Iterable<String> _listRecursive(Directory dir) {
  return dir
      .listSync(recursive: true)
      .where((e) => e is! Directory)
      .map((e) => e.path);
}

void main(List<String> argv) {
  final target = argv.isNotEmpty
      ? argv[0]
      : throw Exception('No zip file specified!');
  final entries = _expand(
    argv.sublist(1),
  ).map((f) => ZipFileEntry(name: f, data: File(f).openRead()));
  entries.map((e) => '  adding: ${e.name}').forEach(print);

  if (entries.isEmpty) {
    return;
  }
  final archive = ZipArchive(entries);
  archive.zip().pipe(File(target).openWrite());
}
