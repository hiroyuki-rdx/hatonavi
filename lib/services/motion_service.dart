// Web専用実装。ネイティブ対応時は motion / sensors_plus 等に差し替えること。
//
// このファイルは `dart:html` / `dart:js_util` を使うため Flutter Web でのみ動作する。
// 加速度センサー（DeviceMotion）でスマホの「走っている／激しく動いている」状態を
// 検知し、歩きスマホ・走り回り防止のロック表示に使う（企画書 4-◆安全性への徹底配慮）。

import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:math';

/// 加速度センサーから「子供の歩行速度を超えた動き（早歩き・走り）」を検知するサービス。
///
/// [runningStream] が true を流している間は速すぎる（＝画面ロック＆警告すべき）。
/// センサー非対応・未許可の端末では**何も流さない**ため、ロックは出ず
/// アプリは通常どおり進行する（デモがセンサー有無で止まらない安全設計）。
class MotionService {
  /// 「子供の平均的な歩行速度を超えた（早歩き・走り）」とみなす合成加速度
  /// （重力除外, m/s^2）のしきい値。落ち着いた歩行 ~1〜3／早歩き ~3〜5／走り ~6〜15。
  /// ナビ用のゆっくり歩行は許し、それより速いと警告する狙いで 4.0（小さいほど敏感）。
  static const double _walkAlertThreshold = 4.0;

  /// 単発の衝撃での誤発火を防ぐため、しきい値超えがこの時間続いたら警告する。
  static const int _sustainMs = 500;

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
    DateTime? overSince; // しきい値を超え始めた時刻（持続判定用）
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
        ema = ema * 0.7 + mag * 0.3; // ノイズを平滑化

        if (ema > _walkAlertThreshold) {
          // 歩行速度超えが _sustainMs 続いたら警告（単発の衝撃は無視）。
          overSince ??= DateTime.now();
          if (DateTime.now().difference(overSince!).inMilliseconds >=
              _sustainMs) {
            calmTimer?.cancel();
            calmTimer = null;
            setRunning(true);
          }
        } else {
          overSince = null;
          if (isRunning && calmTimer == null) {
            // 落ち着いたら少し待ってから解除する。
            calmTimer = Timer(const Duration(milliseconds: 1200), () {
              calmTimer = null;
              setRunning(false);
            });
          }
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
