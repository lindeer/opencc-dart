import 'package:opencc/opencc.dart';
import 'package:test/test.dart';

void main() {
  test('s2t', () {
    final zh = ZhConverter('s2t');
    expect(zh.convert('以包含要提交的内容'), '以包含要提交的內容');
    expect(zh.convert('为什么，why'), '爲什麼，why');
    expect(zh.convert('人生'), '人生');
    expect(zh.convert(''), '');
    expect(zh.convert('  \n  '), '  \n  ');
    expect(zh.convert('鬆開'), '鬆開');
  });

  test('t2s', () {
    final zh = ZhConverter('t2s');
    expect(zh.convert('米騰思非常興奮，輕鬆地爬上了樹'), '米腾思非常兴奋，轻松地爬上了树');
    expect(zh.convert('爲什麼，why'), '为什么，why');
    expect(zh.convert('人生'), '人生');
    expect(zh.convert(''), '');
    expect(zh.convert('  \n  '), '  \n  ');
    expect(zh.convert('松开'), '松开');
  });

  test('stream s2t', () async {
    final zh = ZhTransformer('s2t');
    final s = '有一个叫Timmy的小男孩。\n提米喜欢整天玩他的玩具车';
    final text = await Stream.value(s).transform(zh).join('');
    expect(text, '有一個叫Timmy的小男孩。\n提米喜歡整天玩他的玩具車');
  });
}
