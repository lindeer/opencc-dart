// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:path/path.dart' as p;
import 'package:zip2/zip2.dart';

const _libName = 'opencc';

void main(List<String> args) async {
  await build(args, _builder);
}

Future<void> _builder(BuildInput input, BuildOutputBuilder output) async {
  final targetOS = input.config.code.targetOS;
  final arch = input.config.code.targetArchitecture;
  final outputDirectory = Directory.fromUri(input.outputDirectory);
  final file = await _download(
    targetOS,
    arch,
    targetOS == OS.iOS ? input.config.code.iOS.targetSdk : null,
    outputDirectory,
  );

  final libFilename = input.config.code.targetOS.dylibFileName(_libName);
  final archive = file.openSync().unzip();
  final libEntry = archive[libFilename];
  const resDirName = 'opencc';
  final sep = Platform.pathSeparator;
  final resEntries = archive.entries.where(
    (f) => f.name.startsWith('$resDirName$sep') && !f.name.endsWith(sep),
  );
  if (libEntry != null) {
    final outLibFile = File.fromUri(input.outputDirectory.resolve(libFilename));
    stderr.write("Extract '${libEntry.name}' -> $outLibFile");
    await libEntry.data.pipe(outLibFile.openWrite());
  }

  final sharedDir = String.fromEnvironment(
    "OPENCC_SHARED_DIR",
    defaultValue: ".dart_tool/share",
  );

  final resUri = Uri.directory(sharedDir);
  final dir = Directory.fromUri(resUri);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  for (final e in resEntries) {
    final filename = p.relative(e.name, from: resDirName);
    final f = File.fromUri(resUri.resolve(filename));
    final parent = f.parent;
    if (!parent.existsSync()) {
      parent.create(recursive: true);
    }
    stderr.writeln("Extract '${e.name}' -> '${f.path}'");
    await e.data.pipe(f.openWrite());
  }
  stderr.writeln("Unzip $file done.");

  final targetName = targetOS.dylibFileName(input.packageName);
  output.assets.code.add(
    CodeAsset(
      package: input.packageName,
      name: 'src/lib_$_libName.dart',
      linkMode: DynamicLoadingBundled(),
      file: outputDirectory.uri.resolve(targetName),
    ),
  );
}

const _url = 'https://github.com/lindeer/opencc-dart/releases/latest/download';

Future<HttpClientResponse> _httpGet(HttpClient client, Uri uri) async {
  final request = await client.getUrl(uri);
  request.followRedirects = true;
  return await request.close();
}

Future<File> _download(
  OS os,
  Architecture arch,
  IOSSdk? iOSSdk,
  Directory outDir,
) async {
  final suffix = iOSSdk == null ? '' : '-$iOSSdk';
  final proxy = String.fromEnvironment('GITHUB_PROXY');
  final prefix = (proxy.isEmpty || proxy.endsWith('/')) ? proxy : '$proxy/';
  final uri = Uri.parse('$prefix$_url/opencc-$os-$arch$suffix.zip');
  stderr.writeln("Downloading '$uri' ...");
  final client = HttpClient();
  var response = await _httpGet(client, uri);
  while (response.isRedirect) {
    response.drain();
    final location = response.headers.value(HttpHeaders.locationHeader);
    stderr.writeln("Redirecting $location ...");
    if (location != null) {
      response = await _httpGet(client, uri.resolve(location));
    }
  }
  if (response.statusCode != 200) {
    throw ArgumentError('The request to $uri failed(${response.statusCode}).');
  }
  final archive = File.fromUri(outDir.uri.resolve(p.basename(uri.path)));
  await archive.create();
  await response.pipe(archive.openWrite());
  stderr.writeln("Download done. Zip archive: '${archive.path}'");
  return archive;
}
