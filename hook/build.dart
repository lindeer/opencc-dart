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

  final make = await Process.start(
    'unzip',
    [
      '-o',
      file.path,
    ],
    workingDirectory: input.outputDirectory.path,
  );

  stdout.addStream(make.stdout);
  stderr.addStream(make.stderr);
  final code = await make.exitCode;
  if (code != 0) {
    exit(code);
  }
  print("Unzip '$file' done.");
  /*
  final fileHash = await hashAsset(file);
  final expectedHash =
  assetHashes[input.config.code.targetOS.dylibFileName(
    createTargetName(
      targetOS.name,
      targetArchitecture.name,
      iOSSdk?.type,
    ),
  )];
  if (fileHash != expectedHash) {
    throw Exception(
      'File $file was not downloaded correctly. '
          'Found hash $fileHash, expected $expectedHash.',
    );
  }
  */
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

const _url = 'https://github.com/dart-lang/native/releases/download';

Future<File> _download(
    OS os,
    Architecture arch,
    IOSSdk? iOSSdk,
    Directory outDir,
    ) async {

  final suffix = iOSSdk == null ? '' : '-$iOSSdk';
  final uri = Uri.parse('http://127.0.0.1:8000/opencc-$os-$arch$suffix.zip');
  print("Downloading '$uri' ...");
  final request = await HttpClient().getUrl(uri);
  final response = await request.close();
  if (response.statusCode != 200) {
    throw ArgumentError('The request to $uri failed.');
  }
  print("Download done.");
  final archive = File.fromUri(outDir.uri.resolve(p.basename(uri.path)));
  print("zip archive: $archive");
  await archive.create();
  await response.pipe(archive.openWrite());
  return archive;
}
