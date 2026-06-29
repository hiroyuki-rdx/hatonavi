// 動作確認テスト：完了画面(StickerScreen)に「おうちのひとへ きょうのまなび」カードが
// 表示され、AI(GeminiService)がローカルで使えない＝失敗するときでも、固定フォールバック文
// に切り替わって「カードが必ず埋まる＝デモが止まらない」ことを検証する。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hatopro_01/models.dart';
import 'package:hatopro_01/screens/sticker_screen.dart';

void main() {
  testWidgets('完了画面に保護者サマリカードが出る／AI失敗時はフォールバック文で埋まる',
      (WidgetTester tester) async {
    // ポイント永続化(shared_preferences)をテスト用にモック。
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MaterialApp(
        home: StickerScreen(
          totalItems: 2,
          collected: sampleItems.take(2).toList(),
          earnedPoints: 2,
        ),
      ),
    );

    // initState の Future を起動 → 「おかいけい演出」(1300ms)を抜ける → 結果画面へ。
    // ローカルには /api/gemini が無いので generateParentSummary は失敗し null → フォールバックへ。
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));

    // カードの見出しが出ている。
    expect(find.text('おうちのひとへ きょうのまなび'), findsOneWidget);
    // 「AIがまとめました」のラベルが出ている。
    expect(find.text('AIが きょうの まなびを まとめました'), findsOneWidget);
    // 本文（AI失敗時のフォールバック）が空でなく、食育の文言を含む。
    expect(find.textContaining('しょくいく'), findsWidgets);
    // ローディングのスピナーは消えている（取得が完了している）。
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
