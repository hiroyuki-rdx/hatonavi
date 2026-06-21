import 'package:shared_preferences/shared_preferences.dart';

/// ポイントをスマホ内（端末ローカル）に永続保存するサービス。
///
/// `shared_preferences` を使い、キー `'total_points'` に
/// 累計ポイントを int として読み書きする。
/// 画面担当（A）はこのクラスの静的メソッドを通じてポイントを操作する。
class PointService {
  /// 読み書きに使う SharedPreferences のキー。
  static const String _totalKey = 'total_points';

  /// スタンプ1個に必要なポイント（2ポイントごとに1スタンプ）。
  static const int pointsPerStamp = 2;

  /// シール1枚と交換するのに必要なスタンプ数。
  static const int stampsToRedeem = 5;

  /// シール交換に必要な累計ポイント（＝2ポイント×5スタンプ＝10）。
  /// 画面側でこの定数を参照して交換可否や残りポイントを表示する。
  static const int stickerThreshold = pointsPerStamp * stampsToRedeem;

  /// 累計ポイントを読み込んで返す。
  ///
  /// 一度も保存されていない場合は 0 を返す。
  static Future<int> loadTotal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalKey) ?? 0;
  }

  /// 指定したポイントを累計に加算して保存する。
  ///
  /// 現在の累計を読み込み、[points] を足した値を書き戻す。
  static Future<void> add(int points) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_totalKey) ?? 0;
    await prefs.setInt(_totalKey, current + points);
  }

  /// 累計ポイントから、スタンプカードに押されているスタンプ数（0〜[stampsToRedeem]）。
  /// 2ポイントごとに1個。カードの上限（5個）で頭打ちにする。
  static int stampsFor(int total) {
    final s = total ~/ pointsPerStamp;
    if (s < 0) return 0;
    return s > stampsToRedeem ? stampsToRedeem : s;
  }

  /// 交換できる状態か（累計が [stickerThreshold] 以上）。
  static bool canRedeem(int total) => total >= stickerThreshold;

  /// シールと交換する：累計から [stickerThreshold] を引いて保存し、引いた後の累計を返す。
  /// しきい値未満のときは何もしない（現在値を返す）。
  static Future<int> redeem() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_totalKey) ?? 0;
    final next = current >= stickerThreshold ? current - stickerThreshold : current;
    await prefs.setInt(_totalKey, next);
    return next;
  }
}
