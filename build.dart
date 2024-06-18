// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, File, Process, exit, stderr, stdout;
import 'package:glob/glob.dart' show Glob;
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as p;
import 'package:native_assets_cli/native_assets_cli.dart';

const packageName = 'opencc';
const _repoLibName = 'libopencc.so';

/// Implements the protocol from `package:native_assets_cli` by building
/// the C code in `src/` and reporting what native assets it built.
void main(List<String> args) async {
  await build(args, _builder);
}

Future<void> _checkCmd(String cmd) async {
  final proc = await Process.start(
    'which',
    [cmd],
  );
  final code = await proc.exitCode;
  if (code != 0) {
    throw Exception("'$cmd' not found!");
  }
}

Future<void> _builder(BuildConfig buildConfig, BuildOutput buildOutput) async {
  _checkCmd('cmake');
  _checkCmd('make');
  final pkgRoot = buildConfig.packageRoot;

  final buildDir = p.join('src', 'build');
  final dir = Directory(buildDir);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  final output = buildConfig.outputDirectory.path;
  final cmake = await Process.start(
    'cmake',
    [
      '..',
      '-DCMAKE_BUILD_TYPE=Release',
      '-DSHARE_INSTALL_PREFIX=$output',
    ],
    workingDirectory: buildDir,
  );
  stdout.addStream(cmake.stdout);
  stderr.addStream(cmake.stderr);
  final code = await cmake.exitCode;
  if (code != 0) {
    exit(code);
  }
  final make = await Process.start(
    'make',
    [
      'Dictionaries',
    ],
    workingDirectory: buildDir,
  );
  stdout.addStream(make.stdout);
  stderr.addStream(make.stderr);
  final code2 = await make.exitCode;
  if (code2 != 0) {
    exit(code2);
  }

  final linkMode = _linkMode(buildConfig.linkModePreference);
  final libName = buildConfig.targetOS.libraryFileName(packageName, linkMode);
  final libUri = buildConfig.outputDirectory.resolve(libName);
  final uri = pkgRoot.resolve(p.join(buildDir, 'src', _repoLibName));
  final file = File.fromUri(uri).resolveSymbolicLinksSync();
  File(file).renameSync(libUri.path);

  buildOutput.addAsset(NativeCodeAsset(
    package: packageName,
    name: 'src/lib_$packageName.dart',
    linkMode: linkMode,
    os: buildConfig.targetOS,
    file: libUri,
    architecture: buildConfig.targetArchitecture,
  ));

  final src = [
    'src/src/BinaryDict.cpp',
    'src/src/Config.cpp',
    'src/src/ConversionChain.cpp',
    'src/src/Conversion.cpp',
    'src/src/Converter.cpp',
    'src/src/DartsDict.cpp',
    'src/src/DictConverter.cpp',
    'src/src/Dict.cpp',
    'src/src/DictEntry.cpp',
    'src/src/DictGroup.cpp',
    'src/src/Lexicon.cpp',
    'src/src/MarisaDict.cpp',
    'src/src/MaxMatchSegmentation.cpp',
    'src/src/PhraseExtract.cpp',
    'src/src/Segmentation.cpp',
    'src/src/SerializedValues.cpp',
    'src/src/SimpleConverter.cpp',
    'src/src/TextDict.cpp',
    'src/src/UTF8StringSlice.cpp',
    'src/src/UTF8Util.cpp',
  ];

  buildOutput.addDependencies([
    ...src.map((s) => pkgRoot.resolve(s)),
    pkgRoot.resolve('build.dart'),
  ]);

  final dataDir = p.join(output, 'opencc');
  final d = Directory(dataDir);
  if (!d.existsSync()) {
    d.createSync();
  }
  for (final f in Glob('src/build/data/*.ocd2').listSync()) {
    final path = p.join(dataDir, p.basename(f.path));
    f.renameSync(path);
  }
  for (final f in Glob('src/data/config/*.json').listSync()) {
    final path = p.join(dataDir, p.basename(f.path));
    File(f.path).copySync(path);
  }
}

LinkMode _linkMode(LinkModePreference preference) {
  if (preference == LinkModePreference.dynamic ||
      preference == LinkModePreference.preferDynamic) {
    return DynamicLoadingBundled();
  }
  assert(preference == LinkModePreference.static ||
      preference == LinkModePreference.preferStatic);
  return StaticLinking();
}
