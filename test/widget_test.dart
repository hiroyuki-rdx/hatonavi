// アプリ起動のスモークテスト。
// ホーム画面が表示され、開始ボタンが出ることだけを確認する。

import 'package:flutter_test/flutter_test.dart';

import 'package:hatopro_01/main.dart';

void main() {
  testWidgets('ホーム画面が表示される', (WidgetTester tester) async {
    await tester.pumpWidget(const HatoNaviApp());

    // ホームの開始ボタンが表示されていること。
    expect(find.text('クエストをはじめる！'), findsOneWidget);
  });
}
