// 非Web（テストが走る Dart VM など）向けの no-op スタブ。
// Web では speech_service_web.dart が使われる（speech_service.dart の条件付きエクスポート）。
// 公開APIは web 実装と一致させ、呼び出し側は変更不要。何もしないので落ちない。
class SpeechService {
  /// iOS音声の“解放”（Webのみ意味を持つ）。VMでは何もしない。
  static void unlock() {}

  /// テキスト読み上げ（Webのみ）。VMでは何もしない。
  static void speak(String text) {}
}
