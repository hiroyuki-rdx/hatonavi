// 非Web（テストが走る Dart VM など）向けの no-op スタブ。
// Web では compass_service_web.dart が使われる（compass_service.dart の条件付きエクスポート）。
// 公開API（static オフセット値 / headingStream / requestPermission）は web 実装と一致させる。
import 'dart:async';

class CompassService {
  /// 角度基準オフセット（Webのみ意味を持つ）。
  static double baselineOffsetDeg = 0.0;

  /// 店舗マップ北と地磁気北のズレ（較正値・static）。Web実装と同じく全体で共有する。
  static double storeNorthOffsetDeg = 0.0;

  /// 非Webでは方位を流さない（北固定の0を一度だけ流す）。
  Stream<double> get headingStream => Stream<double>.value(0);

  /// 非Webでは権限不要。常に true。
  Future<bool> requestPermission() async => true;
}
