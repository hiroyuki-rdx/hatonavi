// 音声読み上げサービスの「窓口」。
//
// Web（dart:html が使える環境）では speech_service_web.dart の実装を、
// それ以外（Flutter のユニットテストが走る Dart VM など）では
// speech_service_stub.dart の no-op 実装を、条件付きエクスポートで切り替える。
// これにより `flutter test` でも `dart:html` のコンパイルエラーにならず、
// Web 本番の挙動は web 実装と完全に同一のまま保たれる。
export 'speech_service_stub.dart'
    if (dart.library.html) 'speech_service_web.dart';
