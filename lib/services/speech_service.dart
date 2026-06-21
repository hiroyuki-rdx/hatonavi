// Web専用実装。ネイティブ対応時は flutter_tts 等に差し替えること。
//
// ブラウザの Web Speech API（speechSynthesis）で日本語テキストを読み上げる。
// 危険エリア接近時の「音声アラート」（企画書 4-◆安全性／危険箇所のポップアップ）に使う。
// 権限要求は不要で、対応ブラウザならそのまま鳴る。非対応・例外時は無音で続行する。

import 'dart:html' as html;

class SpeechService {
  /// [text] を日本語で読み上げる。絵文字・改行は読み上げ向けに整える。
  static void speak(String text) {
    try {
      final synth = html.window.speechSynthesis;
      if (synth == null) return;
      final cleaned = text
          .replaceAll('⚠️', '')
          .replaceAll('\n', ' ')
          .trim();
      final utterance = html.SpeechSynthesisUtterance(cleaned)
        ..lang = 'ja-JP'
        ..rate = 1.0
        ..pitch = 1.0;
      // 直前の読み上げが残っていれば止めてから話す（重なり防止）。
      synth.cancel();
      synth.speak(utterance);
    } catch (_) {
      // 非対応ブラウザなどでは無音で続行（デモを止めない）。
    }
  }
}
