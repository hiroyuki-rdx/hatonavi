// 非Web（テストが走る Dart VM など）向けの no-op スタブ。
// Web では motion_service_web.dart が使われる（motion_service.dart の条件付きエクスポート）。
// 公開API（requestPermission / runningStream）は web 実装と一致させる。
import 'dart:async';

class MotionService {
  /// 非Webでは権限不要。常に true。
  Future<bool> requestPermission() async => true;

  /// 非Webでは走行を検知しない（何も流さない＝ロックは出ない）。
  Stream<bool> get runningStream => Stream<bool>.empty();
}
