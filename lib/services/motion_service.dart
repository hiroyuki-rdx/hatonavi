// Web専用実装。ネイティブ対応時は motion / sensors_plus 等に差し替えること。
//
// このファイルは `dart:html` / `dart:js_util` を使うため Flutter Web でのみ動作する。
// 加速度センサー（DeviceMotion）でスマホの「走っている／激しく動いている」状態を
// 検知し、歩きスマホ・走り回り防止のロック表示に使う（企画書 4-◆安全性への徹底配慮）。

import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:math';

/// 加速度センサーから「走行（激しい動き）」を検知するサービス。
///
/// [runningStream] が true を流している間は走っている（＝画面ロックすべき）。
/// センサー非対応・未許可の端末では**何も流さない**ため、ロックは出ず
/// アプリは通常どおり進行する（デモがセンサー有無で止まらない安全設計）。
class MotionService {
  /// この合成加速度（重力除外, m/s^2）を超えたら「走っている」とみなすしきい値。
  /// 歩行は数 m/s^2、走り・激しい振りは 10〜20 程度。実機で微調整可。
  static const double _runThreshold = 7.0;

  /// 走行センサーの利用権限を要求する。許可されたら true を返す。
  ///
  /// iOS 13+ Safari は `DeviceMotionEvent.requestPermission()` を**タップ起点**で
  /// 呼ぶ必要がある（[CompassService.requestPermission] と同じ作法）。
  /// 非対応環境（Android / PC）や例外時は true を返して続行する。
  Future<bool> requestPermission() async {
    try {
      final dynamic motionEvent =
          js_util.getProperty(html.window, 'DeviceMotionEvent');
      if (motionEvent == null) return true;
      final bool hasRequest =
          js_util.hasProperty(motionEvent, 'requestPermission');
      if (!hasRequest) return true;
      final dynamic result = await js_util.promiseToFuture<dynamic>(
        js_util.callMethod(motionEvent, 'requestPermission', <Object?>[]),
      );
      return result == 'granted';
    } catch (_) {
      return true;
    }
  }

  /// 走行中かどうか（true=走っている）を流すストリーム。状態が変わったときだけ流す。
  Stream<bool> get runningStream {
    final controller = StreamController<bool>.broadcast();
    StreamSubscription<html.DeviceMotionEvent>? sub;
    bool isRunning = false;
    double ema = 0.0; // 平滑化した動きの強さ
    Timer? calmTimer; // 落ち着いてから解除するためのタイマー（チラつき防止）

    void setRunning(bool v) {
      if (v == isRunning) return;
      isRunning = v;
      controller.add(v);
    }

    void onMotion(html.DeviceMotionEvent ev) {
      try {
        double mag;
        final acc = ev.acceleration;
        if (acc?.x != null) {
          // 重力除外の加速度が取れる端末（iOS等）。
          final x = acc!.x!.toDouble();
          final y = acc.y!.toDouble();
          final z = acc.z!.toDouble();
          mag = sqrt(x * x + y * y + z * z);
        } else {
          // フォールバック：重力込みの加速度から約9.8を引いて動きの強さを近似。
          final g = ev.accelerationIncludingGravity;
          if (g?.x == null) return;
          final x = g!.x!.toDouble();
          final y = g.y!.toDouble();
          final z = g.z!.toDouble();
          mag = (sqrt(x * x + y * y + z * z) - 9.8).abs();
        }
        ema = ema * 0.6 + mag * 0.4; // ノイズを平滑化

        if (ema > _runThreshold) {
          calmTimer?.cancel();
          calmTimer = null;
          setRunning(true);
        } else if (isRunning && calmTimer == null) {
          // 落ち着いたら少し待ってから解除する。
          calmTimer = Timer(const Duration(milliseconds: 1200), () {
            calmTimer = null;
            setRunning(false);
          });
        }
      } catch (_) {
        // 壊れたイベントは無視。
      }
    }

    controller.onListen = () {
      try {
        sub = html.window.onDeviceMotion.listen(onMotion);
      } catch (_) {
        // 非対応端末：ロックは出さず通常進行（true を一切流さない）。
      }
    };
    controller.onCancel = () {
      sub?.cancel();
      calmTimer?.cancel();
    };

    return controller.stream;
  }
}
