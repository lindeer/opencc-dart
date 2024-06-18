
A dart wrapper of project [opencc](https://github.com/BYVoid/OpenCC).

依赖包需要开启native-assets特性：`dart --enable-experiment=native-assets run bin/opencc.dart`

## 直接使用

```bash
dart pub global activate opencc

# 简转繁
opencc '简体转化为繁体' # 默认带参数 [-c s2t]

# 多段文本繁转简
opencc -c t2s '繁體轉化爲簡體' '繁體轉化爲簡體2'

# 多个文件简转繁

opencc -c s2t 简体文件1.txt 简体文件2.txt
```

## 开发引入

```yaml
opencc: ^1.0.0
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
  .transform(ZhTransformer(config))
  .transform(utf8.encoder);

await File(output).openWrite().addStream(ss);
```
