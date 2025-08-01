
A dart wrapper of project [opencc](https://github.com/BYVoid/OpenCC).

The dependent shared library would be downloaded from remote.

`OPENCC_SHARED_DIR=.dart_tool/share dart --enable-experiment=native-assets run -v bin/opencc.dart '凭君传语报平安'`


## 使用说明

1. dart依赖`native-assets`特性，dart3.8以后仅在dev渠道中具备。dev渠道不稳定，某些版本会出现匪夷所思的问题，目前测试`3.10.0-14.0.dev`是可用的。
2. 远程编译`OpenCC`无法通过`-DSHARE_INSTALL_PREFIX=`将资源路径设置到共享库中，已经通过改造源码可通过环境变量`OPENCC_SHARED_DIR`加载配置资源。
3. 命令行设置`OPENCC_SHARED_DIR=.dart_tool/share`无法将环境变量传递到dart运行时上下文，需要通过`dart run -DOPENCC_SHARED_DIR=.dart_tool/share`方法，但`3.10.0-14.0.dev`版本中`-D`或`--define=`方式传递环境变量的方式是失效的。目前`OPENCC_SHARED_DIR=.dart_tool/share`不可缺省，也不可自定义路径。编译生成资源的管理需要(data_assets)[https://github.com/dart-lang/sdk/issues/54003]的完善。
4. 远程共享库在`ubuntu:18.04`的容器中编译，最低可支持较为普遍的`GLIBC_2.27`。
5. 如果无法直接下载github保存的预编译共享库，可通过代理下载：
  5.1 以linux方式设置环境变量`export https_proxy=`。
  5.2 定义dart环境变量`dart run -DGITHUB_PROXY=`，最终下载路径为`$GITHUB_PROXY/https://github.com/lindeer/opencc-dart/releases/latest/download/opencc-$os-$arch.zip`。

## 直接使用

```bash
dart pub global activate opencc

# 简转繁
opencc '简体转化为繁体' # 默认带参数 [-c s2t]

# 多段文本繁转简
opencc -c t2s '繁體轉化爲簡體' '繁體轉化爲簡體2'

# 多个文件简转繁并且直接在原文件修改

opencc -i -c s2t 简体文件1.txt 简体文件2.txt
```

## 开发引入

```yaml
opencc: ^1.2.0-dev.1
```

### 处理小段文本
```dart
import 'package:opencc/opencc.dart' show ZhConverter;

final zh = ZhConverter('s2t');
final text = zh.convert(input);
```

### 处理流文本
```dart
import 'package:opencc/opencc.dart' show ZhTransformer;

final ss = file.openRead()
  .transform(utf8.decoder)
  .transform(ZhTransformer('t2s'))
  .transform(utf8.encoder);

await File(output).openWrite().addStream(ss);
```

### 容器编译

本地容器可通过以下命令运行`tool/compile.sh`中的内容：

```
docker run -it -v $PWD:/work -w /work ubuntu:18.04 /bin/bash
```
