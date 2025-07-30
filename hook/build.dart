// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:path/path.dart' as p;

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

  final args = ['-o', file.path];
  final make = await Process.start(
    'unzip',
    args,
    workingDirectory: input.outputDirectory.path,
  );
  stdout.addStream(make.stdout);
  stderr.addStream(make.stderr);
  final code = await make.exitCode;
  if (code != 0) {
    exit(code);
  }
  stderr.writeln("Unzip '$file' done.");
  final sharedDir = String.fromEnvironment(
    "OPENCC_SHARED_DIR",
    defaultValue: ".dart_tool/share",
  );

  if (sharedDir.isNotEmpty) {
    final dir = Directory(sharedDir);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
    final resDir = Directory.fromUri(input.outputDirectory.resolve('opencc'));
    resDir.renameSync(sharedDir);
  }
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

const _ver = 'opencc-v1';
const _url = 'https://github.com/lindeer/opencc-dart/releases/download/$_ver';

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
  final uri = Uri.parse('$_url/opencc-$os-$arch$suffix.zip');
  stderr.writeln("Downloading '$uri' ...");
  final client = HttpClient();
  var response = await _httpGet(client, uri);
  while (response.isRedirect) {
    response.drain();
    final location = response.headers.value(HttpHeaders.locationHeader);
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
