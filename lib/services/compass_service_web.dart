// Web専用実装。ネイティブ対応時は sensors_plus 等に差し替えること。
//
// このファイルは `dart:html` を使うため Flutter Web でのみ動作する。
// iOS / Android のネイティブアプリとしてビルドする場合は、
// 同じ公開API（headingStream / requestPermission）を保ったまま
// sensors_plus などのプラグインを使った実装に差し替える想定。

import 'dart:async';
import 'dart:html' as html;
// ignore: uri_does_not_exist （Web専用。dart:js_util は web ビルドでのみ解決される。解析の偽陽性を抑止）
import 'dart:js_util' as js_util;
import 'dart:math';

/// デバイスの方位センサー（コンパス）と連携するサービス。
///
/// ブラウザの DeviceOrientation イベントを購読し、
/// 北を 0 度とした 0〜360 度の方位を [headingStream] で流す。
///
/// 端末ごとの違いを吸収する:
/// - iOS Safari: `event.webkitCompassHeading`（北=0・時計回りの絶対方位）を使う。
///   さらに利用には [requestPermission] をユーザー操作起点で呼ぶ必要がある。
/// - Android Chrome 等: `deviceorientationabsolute` の `alpha`（反時計回り）を
///   `360 - alpha` で北基準に変換する。
class CompassService {
  /// 角度基準値（オフセット, 度）。店舗マップの向きに合わせる／手動キャリブレーション用。
  /// 例：店舗が真北から30度ずれていれば 30 を入れると棚方向の見え方が合う。
  static double baselineOffsetDeg = 0.0;

  /// 店舗マップの「北」と、実際の地磁気の北とのズレ（度, 0〜360）。
  /// 売り場座標(storeAreas)で計算した方位角は「マップ上の北」基準なので、
  /// マップ全体が実際の北からどれだけ回転しているかをこの値で吸収する。
  /// CompassScreen の「むきを あわせる」ワンタップ較正で更新され、
  /// static なので全ミッションを通して保持される。
  static double storeNorthOffsetDeg = 0.0;

  /// 円環スムージング係数（0〜1, 小さいほど滑らかで反応はゆっくり）。針のブレを抑える。
  static const double _smoothing = 0.2;

  /// この度数未満の変化は出力しない（針の細かなチラつき防止）。
  static const double _minDeltaDeg = 1.0;

  /// 0〜360度（北=0）の方位を流すストリーム。
  ///
  /// 絶対方位（`deviceorientationabsolute`）を最優先で使い、取れない端末でのみ
  /// `deviceorientation`（iOSは `webkitCompassHeading`、他は absolute==true の alpha）
  /// を使う。**2方式を混ぜない**ことで象限ごとのズレを防ぐ。
  Stream<double> get headingStream {
    final controller = StreamController<double>.broadcast();
    final List<StreamSubscription<html.Event>> subs = [];

    // 円環スムージング用の状態。角度を単位ベクトル(cos,sin)に直してEMAすることで、
    // 0/360 の境界をまたいでも正しく平滑化でき、針のブレを抑えられる。
    double sx = 0, sy = 0;
    bool hasSmooth = false;
    double lastEmitted = -999;
    bool gotAbsolute = false; // 絶対方位を一度でも受け取ったら相対方位は使わない

    void emit(double rawDeg) {
      // 角度基準値（店舗の向き補正・手動キャリブレーション）を反映する。
      double h = (rawDeg - baselineOffsetDeg) % 360;
      if (h < 0) h += 360;
      final rad = h * pi / 180;
      if (!hasSmooth) {
        sx = cos(rad);
        sy = sin(rad);
        hasSmooth = true;
      } else {
        sx = sx * (1 - _smoothing) + cos(rad) * _smoothing;
        sy = sy * (1 - _smoothing) + sin(rad) * _smoothing;
      }
      double sm = atan2(sy, sx) * 180 / pi;
      if (sm < 0) sm += 360;
      // 微小変化（針のチラつき）は捨てる。初回は必ず出す。
      double d = (sm - lastEmitted).abs();
      if (d > 180) d = 360 - d;
      if (lastEmitted < -100 || d >= _minDeltaDeg) {
        lastEmitted = sm;
        controller.add(sm);
      }
    }

    // 1つの方式だけを採用する（絶対と相対を混ぜると象限ごとにズレるため）。
    void handle(html.Event event, {required bool absolute}) {
      try {
        if (absolute) {
          // deviceorientationabsolute：alpha は北基準（反時計回り）。
          gotAbsolute = true;
          final dynamic alpha = js_util.getProperty(event, 'alpha');
          if (alpha != null) {
            double h = (360 - (alpha as num).toDouble()) % 360;
            if (h < 0) h += 360;
            emit(h);
          }
          return;
        }
        // 以降は deviceorientation（相対の可能性あり）。
        // 絶対方位が取れているなら相対は混ぜない。
        if (gotAbsolute) return;
        // iOS Safari：webkitCompassHeading は北=0・時計回りの絶対方位。
        final dynamic webkit = js_util.getProperty(
          event,
          'webkitCompassHeading',
        );
        if (webkit != null) {
          double h = (webkit as num).toDouble() % 360;
          if (h < 0) h += 360;
          emit(h);
          return;
        }
        // event.absolute == true のときだけ alpha を北基準として採用する。
        final dynamic isAbs = js_util.getProperty(event, 'absolute');
        final dynamic alpha = js_util.getProperty(event, 'alpha');
        if (isAbs == true && alpha != null) {
          double h = (360 - (alpha as num).toDouble()) % 360;
          if (h < 0) h += 360;
          emit(h);
        }
        // それ以外（相対のみ）は方位として信用できないので捨てる。
      } catch (_) {
        // 壊れたイベントは無視して次を待つ。
      }
    }

    controller.onListen = () {
      try {
        // 絶対方位イベント（主に Android Chrome）。これが取れれば最優先。
        subs.add(
          html.window.on['deviceorientationabsolute'].listen(
            (e) => handle(e, absolute: true),
          ),
        );
        // iOS / その他：通常の deviceorientation（絶対が取れていなければ使う）。
        subs.add(
          html.window.onDeviceOrientation.listen(
            (e) => handle(e, absolute: false),
          ),
        );
      } catch (_) {
        // センサー非対応環境では北固定（0）を一度だけ流す。
        controller.add(0);
      }
    };
    controller.onCancel = () {
      for (final s in subs) {
        s.cancel();
      }
      subs.clear();
    };

    return controller.stream;
  }

  /// 方位センサーの利用権限を要求する。許可されたら true を返す。
  ///
  /// iOS 13+ の Safari では `DeviceOrientationEvent.requestPermission()` を
  /// **ユーザー操作（タップ）起点**で呼ぶ必要がある。initState 等から自動で
  /// 呼んでも拒否されるため、必ずボタンのタップハンドラから呼ぶこと。
  /// このメソッドが存在しない環境（Android / PC）では権限不要なので true を返す。
  Future<bool> requestPermission() async {
    try {
      final dynamic orientationEvent = js_util.getProperty(
        html.window,
        'DeviceOrientationEvent',
      );
      if (orientationEvent == null) {
        // DeviceOrientationEvent 自体が無い環境。北固定で動かすため true。
        return true;
      }

      // requestPermission を持つのは iOS Safari のみ。無ければ権限不要。
      final bool hasRequest = js_util.hasProperty(
        orientationEvent,
        'requestPermission',
      );
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
