// Web専用実装。ネイティブ対応時は sensors_plus 等に差し替えること。
//
// このファイルは `dart:html` を使うため Flutter Web でのみ動作する。
// iOS / Android のネイティブアプリとしてビルドする場合は、
// 同じ公開API（headingStream / requestPermission）を保ったまま
// sensors_plus などのプラグインを使った実装に差し替える想定。

import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;

/// デバイスの方位センサー（コンパス）と連携するサービス。
///
/// ブラウザの DeviceOrientation イベントを購読し、
/// 北を 0 度とした 0〜360 度の方位を [headingStream] で流す。
/// iOS Safari では明示的な権限要求が必要なため [requestPermission] を用意する。
class CompassService {
  /// 0〜360度（北=0）の方位を流すストリーム。
  ///
  /// `onDeviceOrientationAbsolute`（絶対方位）を優先し、
  /// 無ければ `onDeviceOrientation` にフォールバックして購読する。
  /// イベントの `alpha`（0〜360）を `360 - alpha` で北基準に変換して流す。
  /// `alpha` が null のイベントはスキップする。
  /// センサー非対応・例外時はクラッシュさせず、北固定（0）を一度だけ流す。
  Stream<double> get headingStream async* {
    try {
      // 絶対方位イベントが使えるか確認し、無ければ相対方位にフォールバック。
      final bool hasAbsolute =
          js_util.hasProperty(html.window, 'ondeviceorientationabsolute');
      // `dart:html` の Window には絶対方位用の getter が無いため、
      // イベント名を直接指定して型付きストリームを取得する。
      final Stream<html.DeviceOrientationEvent> source = hasAbsolute
          ? const html.EventStreamProvider<html.DeviceOrientationEvent>(
              'deviceorientationabsolute',
            ).forTarget(html.window)
          : html.window.onDeviceOrientation;

      await for (final html.DeviceOrientationEvent event in source) {
        final double? alpha = event.alpha?.toDouble();
        if (alpha == null) {
          // 方位が取得できないイベントはスキップ。
          continue;
        }
        // alpha は反時計回りなので、北基準（時計回り）へ変換する。
        double heading = 360 - alpha;
        // 念のため 0〜360 の範囲に正規化する。
        heading = heading % 360;
        if (heading < 0) heading += 360;
        yield heading;
      }
    } catch (_) {
      // センサー非対応環境などで例外が出た場合は北固定で続行する。
      yield 0;
    }
  }

  /// 方位センサーの利用権限を要求する。許可されたら true を返す。
  ///
  /// iOS 13+ の Safari では `DeviceOrientationEvent.requestPermission()` を
  /// ユーザー操作起点で呼ぶ必要がある。
  /// このメソッドが存在しない環境（Android / PC）では権限不要なので true を返す。
  /// 例外が出た場合も、続行できるよう true を返す。
  Future<bool> requestPermission() async {
    try {
      // ブラウザ上の DeviceOrientationEvent コンストラクタ（関数オブジェクト）を取得。
      final dynamic orientationEvent =
          js_util.getProperty(html.window, 'DeviceOrientationEvent');
      if (orientationEvent == null) {
        // そもそも DeviceOrientationEvent が無い環境。北固定で動かすため true。
        return true;
      }

      // requestPermission を持つのは iOS Safari のみ。無ければ権限不要。
      final bool hasRequest =
          js_util.hasProperty(orientationEvent, 'requestPermission');
      if (!hasRequest) {
        return true;
      }

      // iOS Safari: requestPermission() は Promise<'granted'|'denied'> を返す。
      final dynamic result = await js_util.promiseToFuture<dynamic>(
        js_util.callMethod(orientationEvent, 'requestPermission', <Object?>[]),
      );
      return result == 'granted';
    } catch (_) {
      // 権限APIで例外が出ても、アプリを止めずに続行する。
      return true;
    }
  }
}
