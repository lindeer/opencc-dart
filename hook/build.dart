// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

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
  output.assets.code.add(
    CodeAsset(
      package: input.packageName,
      name: 'src/lib_$_libName.dart',
      linkMode: DynamicLoadingBundled(),
      file: file.uri,
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
  final targetName = os.dylibFileName('$_libName-$os-$arch$suffix');
  final uri = Uri.parse('$_url/$version/$targetName');
  final request = await HttpClient().getUrl(uri);
  final response = await request.close();
  if (response.statusCode != 200) {
    throw ArgumentError('The request to $uri failed.');
  }
  final library = File.fromUri(outDir.uri.resolve(targetName));
  await library.create();
  await response.pipe(library.openWrite());
  return library;
}
